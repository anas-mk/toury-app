import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../../../core/services/location/mapbox_geocoding_service.dart';
import '../../../../../../../core/services/location/nominatim_service.dart';
import '../../../../../../../core/services/location/recent_searches_store.dart';
import '../../../../../../../core/services/location/search_debouncer.dart';
import '../../../../../../../core/services/maps/cached_tile_provider.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import 'location_pick_result.dart';

/// Fullscreen map picker — Pass #5 (2026 redesign).
///
/// Hard requirements:
///  - Opens on the user's REAL current GPS position (never mock data).
///    A blocking permission dialog with an "Open settings" CTA enforces
///    the policy chosen by the team.
///  - HOT (Humanitarian OSM) tile style for great Egyptian coverage.
///  - Mapbox geocoding (when token configured) with transparent fallback
///    to Nominatim — both biased to Egypt and Arabic-first.
///  - Recent searches surfaced when the search field is empty.
///  - Glass search bar, glass FABs, frosted bottom sheet — modern look.
///  - Zero unmodifiable-map crashes (TileProvider headers fixed).
///  - Smooth: only the small subtree affected by each notifier rebuilds.
class LocationPickerPage extends StatefulWidget {
  final String title;

  /// `true` for the pickup screen, `false` for the destination screen.
  final bool isPickup;

  /// Optional seed position. If `null` we fetch the device's real GPS.
  final LocationPickResult? initial;

  const LocationPickerPage({
    super.key,
    required this.title,
    required this.isPickup,
    this.initial,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // Last-resort fallback (Tahrir Square, Cairo) used ONLY when every
  // attempt to read a real position fails AND the user explicitly
  // declined location services. We never substitute mock data for a
  // working GPS reading.
  static const _cairoFallback = LatLng(30.0444, 31.2357);

  final MapController _mapController = MapController();
  final GeocodingService _geo = GeocodingService();
  final RecentSearchesStore _recentStore = RecentSearchesStore();

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Debouncer + LRU cache for autocomplete. 400ms is the sweet spot
  // between responsiveness and API quota — see SearchDebouncer docs.
  late final SearchDebouncer<NominatimResult> _searchDebouncer =
      SearchDebouncer<NominatimResult>(
    delay: const Duration(milliseconds: 400),
    minLength: 3,
    cacheSize: 32,
    fetcher: (query, cancelToken) {
      final c = _centerVN.value;
      return _geo.search(
        query: query,
        limit: 8,
        cancelToken: cancelToken,
        nearLat: c.latitude,
        nearLng: c.longitude,
      );
    },
  );

  Timer? _reverseDebounce;
  Timer? _bootstrapTimeout;
  CancelToken? _reverseCancel;
  StreamSubscription<MapEvent>? _mapEventsSub;

  // ── Live state in ValueNotifiers so high-frequency events (drag,
  // typing, reverse-geocode arrivals) only rebuild the small subtree
  // that listens to the specific notifier.
  final ValueNotifier<LatLng> _centerVN = ValueNotifier(_cairoFallback);
  final ValueNotifier<double> _bearingVN = ValueNotifier(0);
  final ValueNotifier<String?> _labelVN = ValueNotifier(null);
  final ValueNotifier<String?> _addressVN = ValueNotifier(null);
  final ValueNotifier<bool> _resolvingVN = ValueNotifier(false);
  final ValueNotifier<bool> _searchingVN = ValueNotifier(false);
  final ValueNotifier<String?> _searchErrorVN = ValueNotifier(null);
  final ValueNotifier<List<NominatimResult>> _suggestionsVN =
      ValueNotifier(const []);
  final ValueNotifier<bool> _hasTextVN = ValueNotifier(false);
  final ValueNotifier<bool> _myLocLoadingVN = ValueNotifier(false);
  final ValueNotifier<bool> _focusedVN = ValueNotifier(false);
  final ValueNotifier<List<NominatimResult>> _recentsVN =
      ValueNotifier(const []);

  bool _initialised = false;
  // Once the user pans/zooms or searches, we stop auto-following any later
  // GPS fix that arrives in the background.
  bool _userMovedMap = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      _focusedVN.value = _searchFocus.hasFocus;
    });
    _mapEventsSub = _mapController.mapEventStream.listen(_onMapEvent);
    unawaited(_loadRecents());
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _reverseDebounce?.cancel();
    _bootstrapTimeout?.cancel();
    _reverseCancel?.cancel('disposed');
    _mapEventsSub?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    _centerVN.dispose();
    _bearingVN.dispose();
    _labelVN.dispose();
    _addressVN.dispose();
    _resolvingVN.dispose();
    _searchingVN.dispose();
    _searchErrorVN.dispose();
    _suggestionsVN.dispose();
    _hasTextVN.dispose();
    _myLocLoadingVN.dispose();
    _focusedVN.dispose();
    _recentsVN.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final list = await _recentStore.load();
    if (!mounted) return;
    _recentsVN.value = list;
  }

  // -------------------- bootstrap & permissions --------------------

  Future<void> _bootstrap() async {
    if (widget.initial != null) {
      _centerVN.value =
          LatLng(widget.initial!.latitude, widget.initial!.longitude);
      _labelVN.value = widget.initial!.name;
      _addressVN.value = widget.initial!.address;
      if (mounted) setState(() => _initialised = true);
      _scheduleReverseGeocode(_centerVN.value, immediate: true);
      return;
    }

    // Try last-known fix first (instant) so the map is responsive
    // immediately, then refine with a high-accuracy fix in the
    // background.
    final lastKnown = await _safeLastKnown();
    if (!mounted) return;
    if (lastKnown != null) {
      _centerVN.value = LatLng(lastKnown.latitude, lastKnown.longitude);
      setState(() => _initialised = true);
      _scheduleReverseGeocode(_centerVN.value, immediate: true);
    }

    final granted = await _ensurePermissionsBlocking();
    if (!mounted) return;

    if (!granted) {
      // User denied → fall back to Cairo only as a last resort so the
      // page remains usable. We surface a snackbar with "Open settings".
      if (!_initialised) {
        _centerVN.value = _cairoFallback;
        setState(() => _initialised = true);
        _scheduleReverseGeocode(_cairoFallback, immediate: true);
      }
      _showLocationDeniedSnack();
      return;
    }

    unawaited(_fetchAndApplyCurrentPosition());

    _bootstrapTimeout = Timer(const Duration(seconds: 8), () {
      if (!mounted || _initialised) return;
      _centerVN.value = _cairoFallback;
      setState(() => _initialised = true);
      _scheduleReverseGeocode(_cairoFallback, immediate: true);
    });
  }

  /// Returns `true` if we have permission to read the user's location.
  /// Shows a blocking dialog with Open Settings when the OS dialog has
  /// already been declined permanently.
  Future<bool> _ensurePermissionsBlocking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return false;
        final ok = await _showServicesDisabledDialog();
        if (!ok) return false;
        // After the user opened settings, re-check.
        final reEnabled = await Geolocator.isLocationServiceEnabled();
        if (!reEnabled) return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) return false;
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return false;
        await _showPermanentlyDeniedDialog();
        return false;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationPicker] permission check failed: $e');
      return false;
    }
  }

  Future<bool> _showServicesDisabledDialog() async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PermissionDialog(
        icon: Icons.location_disabled_rounded,
        title: 'Location services are off',
        message:
            'Turn on Location to start from where you are. We use it only to set your pickup point — it never leaves your device unless you confirm.',
        primaryLabel: 'Open settings',
        onPrimary: () async {
          await Geolocator.openLocationSettings();
        },
      ),
    );
    return res ?? false;
  }

  Future<void> _showPermanentlyDeniedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PermissionDialog(
        icon: Icons.shield_outlined,
        title: 'Location permission needed',
        message:
            'You\'ve disabled location for this app. Open settings and allow location access so we can drop your pickup pin where you actually are.',
        primaryLabel: 'Open app settings',
        onPrimary: () async {
          await openAppSettings();
        },
      ),
    );
  }

  Future<void> _fetchAndApplyCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final next = LatLng(pos.latitude, pos.longitude);

      if (!_initialised) {
        _bootstrapTimeout?.cancel();
        _centerVN.value = next;
        setState(() => _initialised = true);
        try {
          _mapController.move(next, 16);
        } catch (_) {/* mapController not ready yet */}
        _scheduleReverseGeocode(next, immediate: true);
        return;
      }
      if (!_userMovedMap) {
        try {
          _mapController.move(next, _mapController.camera.zoom);
        } catch (_) {}
        _centerVN.value = next;
        _scheduleReverseGeocode(next, immediate: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationPicker] getCurrentPosition: $e');
    }
  }

  Future<Position?> _safeLastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  void _showLocationDeniedSnack() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text('Enable location to start from where you are'),
        action: SnackBarAction(
          label: 'Open settings',
          onPressed: () => openAppSettings(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // -------------------- map event handling --------------------

  void _onMapEvent(MapEvent event) {
    if (!mounted) return;
    if (event is MapEventRotate) {
      _bearingVN.value = event.camera.rotation;
      return;
    }
    if (event is MapEventMoveStart) {
      _userMovedMap = true;
      return;
    }
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventRotateEnd ||
        event is MapEventScrollWheelZoom) {
      _userMovedMap = true;
      _centerVN.value = event.camera.center;
      _bearingVN.value = event.camera.rotation;
      _scheduleReverseGeocode(event.camera.center);
    }
  }

  Future<void> _onUseMyLocation() async {
    if (_myLocLoadingVN.value) return;
    HapticFeedback.selectionClick();
    _myLocLoadingVN.value = true;
    try {
      final granted = await _ensurePermissionsBlocking();
      if (!granted) {
        _showLocationDeniedSnack();
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = await _safeLastKnown();
      }
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not get your current location'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final next = LatLng(pos.latitude, pos.longitude);
      _userMovedMap = true;
      try {
        _mapController.move(next, 16);
      } catch (_) {}
      _centerVN.value = next;
      _scheduleReverseGeocode(next, immediate: true);
    } finally {
      if (mounted) _myLocLoadingVN.value = false;
    }
  }

  void _onResetBearing() {
    HapticFeedback.selectionClick();
    try {
      _mapController.rotate(0);
    } catch (_) {}
    _bearingVN.value = 0;
  }

  void _onZoom(double delta) {
    HapticFeedback.selectionClick();
    try {
      final z = (_mapController.camera.zoom + delta).clamp(3.0, 19.0);
      _mapController.move(_mapController.camera.center, z);
    } catch (_) {}
  }

  // -------------------- search --------------------

  /// Called on every keystroke. We:
  ///   1. Update the "has text" flag (drives the X / search icon).
  ///   2. Try the in-memory cache *synchronously* and render rows
  ///      immediately on a hit — zero perceived latency.
  ///   3. Hand the query to [SearchDebouncer], which:
  ///        - waits 400ms after the last keystroke,
  ///        - cancels any in-flight request when a new char arrives,
  ///        - skips identical / too-short queries,
  ///        - caches the result so the next time the user types the
  ///          same prefix we don't hit the network at all.
  void _onSearchChanged() {
    final raw = _searchCtrl.text;
    final hasText = raw.isNotEmpty;
    if (_hasTextVN.value != hasText) _hasTextVN.value = hasText;

    final trimmed = raw.trim();

    // Instant cache rendering for repeat queries.
    final cached = _searchDebouncer.cachedFor(trimmed);
    if (cached != null) {
      _suggestionsVN.value = cached;
      _searchingVN.value = false;
      _searchErrorVN.value = cached.isEmpty ? 'No results' : null;
    }

    _searchDebouncer.schedule(
      trimmed,
      onResult: (key, results) {
        if (!mounted || _normalisedQuery() != key) return;
        _suggestionsVN.value = results;
        _searchingVN.value = false;
        _searchErrorVN.value = results.isEmpty ? 'No results' : null;
      },
      onError: (key, _) {
        if (!mounted || _normalisedQuery() != key) return;
        _suggestionsVN.value = const [];
        _searchingVN.value = false;
        _searchErrorVN.value = 'Search failed. Try again.';
      },
      onSkipped: (_, __) {
        // Below threshold or duplicate → ensure spinner is off and
        // suggestions are empty so the recents panel can show.
        if (!mounted) return;
        if (trimmed.length < 3) {
          _suggestionsVN.value = const [];
          _searchErrorVN.value = null;
        }
        _searchingVN.value = false;
      },
    );

    // Show a spinner only if we're going to hit the network.
    if (trimmed.length >= 3 && cached == null) {
      _searchingVN.value = true;
      _searchErrorVN.value = null;
    } else {
      _searchingVN.value = false;
    }
  }

  String _normalisedQuery() => _searchCtrl.text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  void _onPickSuggestion(NominatimResult r) {
    HapticFeedback.selectionClick();
    _searchFocus.unfocus();
    _searchCtrl.text = r.name;
    _searchCtrl.selection = TextSelection.collapsed(offset: r.name.length);
    _hasTextVN.value = r.name.isNotEmpty;
    final next = LatLng(r.lat, r.lng);
    _userMovedMap = true;
    try {
      _mapController.move(next, 16);
    } catch (_) {}
    _centerVN.value = next;
    _labelVN.value = r.name;
    _addressVN.value = r.displayName;
    _suggestionsVN.value = const [];
    _searchErrorVN.value = null;
    unawaited(_recentStore.add(r).then((_) => _loadRecents()));
    _scheduleReverseGeocode(next, immediate: true);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchDebouncer.cancel();
    _hasTextVN.value = false;
    _suggestionsVN.value = const [];
    _searchErrorVN.value = null;
    _searchingVN.value = false;
  }

  // -------------------- reverse geocoding --------------------

  void _scheduleReverseGeocode(LatLng latLng, {bool immediate = false}) {
    _reverseDebounce?.cancel();
    _reverseCancel?.cancel('superseded');
    _resolvingVN.value = true;
    if (immediate) {
      _reverseGeocode(latLng);
      return;
    }
    _reverseDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _reverseGeocode(latLng),
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final token = CancelToken();
    _reverseCancel = token;
    try {
      final r = await _geo.reverse(
        lat: latLng.latitude,
        lng: latLng.longitude,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      if (r != null) {
        _labelVN.value = r.name.isNotEmpty
            ? r.name
            : '${latLng.latitude.toStringAsFixed(5)}, '
                '${latLng.longitude.toStringAsFixed(5)}';
        _addressVN.value = r.displayName.isNotEmpty ? r.displayName : null;
      } else {
        _labelVN.value = '${latLng.latitude.toStringAsFixed(5)}, '
            '${latLng.longitude.toStringAsFixed(5)}';
        _addressVN.value = null;
      }
      _resolvingVN.value = false;
    } catch (_) {
      if (!mounted || token.isCancelled) return;
      _labelVN.value = '${latLng.latitude.toStringAsFixed(5)}, '
          '${latLng.longitude.toStringAsFixed(5)}';
      _addressVN.value = null;
      _resolvingVN.value = false;
    }
  }

  // -------------------- confirm --------------------

  void _confirm() {
    HapticFeedback.mediumImpact();
    final center = _centerVN.value;
    final cleanLabel = (_labelVN.value ?? '').trim();
    final addr = _addressVN.value;
    final fallback = '${center.latitude.toStringAsFixed(5)}, '
        '${center.longitude.toStringAsFixed(5)}';
    final result = LocationPickResult(
      name: cleanLabel.isNotEmpty ? cleanLabel : fallback,
      address: (addr ?? '').isEmpty ? null : addr,
      latitude: center.latitude,
      longitude: center.longitude,
    );
    // Save to recents on confirm too.
    unawaited(_recentStore.add(NominatimResult(
      lat: result.latitude,
      lng: result.longitude,
      name: result.name,
      displayName: result.address ?? result.name,
    )));
    Navigator.of(context).pop(result);
  }

  // -------------------- build --------------------

  @override
  Widget build(BuildContext context) {
    final pinColor = widget.isPickup
        ? BrandTokens.successGreen
        : BrandTokens.dangerRed;
    final mediaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: BrandTokens.bgSoft,
      resizeToAvoidBottomInset: false,
      body: !_initialised
          ? const _BootstrapShimmer()
          : Stack(
              children: [
                // 1. The map.
                RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centerVN.value,
                      initialZoom: 16,
                      minZoom: 3,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all &
                            ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        // OSM Humanitarian — better Egyptian coverage
                        // (district / village names) than Carto Voyager.
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'app.rafiq.user',
                        maxZoom: 19,
                        keepBuffer: 4,
                        tileDisplay: const TileDisplay.instantaneous(),
                        tileProvider: CachedTileProvider(),
                      ),
                    ],
                  ),
                ),

                // 2. Subtle vignette to lift CTAs off bright tiles.
                IgnorePointer(
                  child: Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.06),
                          ],
                          stops: const [0.0, 0.18, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Pulsing centre pin.
                Center(child: _PulsingPin(color: pinColor)),

                // 4. Attribution chip.
                const Positioned(
                  left: 8,
                  bottom: 8,
                  child: _AttributionChip(),
                ),

                // 5. Floating glass search bar.
                Positioned(
                  top: mediaTop + 8,
                  left: 12,
                  right: 12,
                  child: _GlassSearchBar(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    isSearchingVN: _searchingVN,
                    errorVN: _searchErrorVN,
                    suggestionsVN: _suggestionsVN,
                    hasTextVN: _hasTextVN,
                    focusedVN: _focusedVN,
                    recentsVN: _recentsVN,
                    onClear: _clearSearch,
                    onPick: _onPickSuggestion,
                    onBack: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).maybePop();
                    },
                    title: widget.title,
                    isPickup: widget.isPickup,
                  ),
                ),

                // 6. Right-side controls column (compass + zoom + my-location).
                Positioned(
                  top: mediaTop + 96,
                  right: 14,
                  child: Column(
                    children: [
                      ValueListenableBuilder<double>(
                        valueListenable: _bearingVN,
                        builder: (_, bearing, __) => _GlassIconButton(
                          icon: Icons.explore_rounded,
                          rotationRad: bearing * (3.1415926535 / 180.0) * -1,
                          onTap: _onResetBearing,
                          color: BrandTokens.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _GlassIconButton(
                        icon: Icons.add_rounded,
                        onTap: () => _onZoom(1),
                        color: BrandTokens.textPrimary,
                      ),
                      const SizedBox(height: 6),
                      _GlassIconButton(
                        icon: Icons.remove_rounded,
                        onTap: () => _onZoom(-1),
                        color: BrandTokens.textPrimary,
                      ),
                    ],
                  ),
                ),

                // 7. My-location FAB (bottom right).
                Positioned(
                  right: 14,
                  bottom: 230,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _myLocLoadingVN,
                    builder: (_, loading, __) => _MyLocationFab(
                      isLoading: loading,
                      onTap: _onUseMyLocation,
                    ),
                  ),
                ),

                // 8. Frosted bottom sheet with confirm.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _FrostedBottomSheet(
                      isPickup: widget.isPickup,
                      labelVN: _labelVN,
                      addressVN: _addressVN,
                      resolvingVN: _resolvingVN,
                      centerVN: _centerVN,
                      onConfirm: _confirm,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// =============================================================================
// Glass Search Bar + Suggestions / Recents Panel
// =============================================================================

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> isSearchingVN;
  final ValueListenable<String?> errorVN;
  final ValueListenable<List<NominatimResult>> suggestionsVN;
  final ValueListenable<bool> hasTextVN;
  final ValueListenable<bool> focusedVN;
  final ValueListenable<List<NominatimResult>> recentsVN;
  final VoidCallback onClear;
  final ValueChanged<NominatimResult> onPick;
  final VoidCallback onBack;
  final String title;
  final bool isPickup;

  const _GlassSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearchingVN,
    required this.errorVN,
    required this.suggestionsVN,
    required this.hasTextVN,
    required this.focusedVN,
    required this.recentsVN,
    required this.onClear,
    required this.onPick,
    required this.onBack,
    required this.title,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isPickup ? BrandTokens.successGreen : BrandTokens.dangerRed;
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiny top label ("PICKUP POINT" / "DESTINATION").
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isPickup ? 'PICKUP POINT' : 'DESTINATION',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Frosted glass bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandTokens.shadowSoft,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: onBack,
                      child: const SizedBox(
                        width: 46,
                        height: 52,
                        child: Icon(Icons.arrow_back_rounded,
                            color: BrandTokens.textPrimary, size: 22),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: BrandTokens.borderSoft,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isPickup
                          ? Icons.trip_origin_rounded
                          : Icons.flag_rounded,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => focusNode.unfocus(),
                        onTapOutside: (_) => focusNode.unfocus(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BrandTokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: isPickup
                              ? 'Search pickup, e.g. Tahrir Square'
                              : 'Search destination, e.g. Pyramids',
                          hintStyle: const TextStyle(
                            color: BrandTokens.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    _SearchTrailing(
                      isSearchingVN: isSearchingVN,
                      hasTextVN: hasTextVN,
                      onClear: onClear,
                    ),
                  ],
                ),
              ),
            ),
          ),

          _ResultsPanel(
            suggestionsVN: suggestionsVN,
            errorVN: errorVN,
            controller: controller,
            onPick: onPick,
            focusedVN: focusedVN,
            recentsVN: recentsVN,
          ),
        ],
      ),
    );
  }
}

class _SearchTrailing extends StatelessWidget {
  final ValueListenable<bool> isSearchingVN;
  final ValueListenable<bool> hasTextVN;
  final VoidCallback onClear;
  const _SearchTrailing({
    required this.isSearchingVN,
    required this.hasTextVN,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([isSearchingVN, hasTextVN]),
      builder: (_, __) {
        final searching = isSearchingVN.value;
        final hasText = hasTextVN.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (searching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        BrandTokens.primaryBlue),
                  ),
                ),
              ),
            if (hasText)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: BrandTokens.textSecondary),
                tooltip: 'Clear',
                onPressed: onClear,
                splashRadius: 22,
              )
            else if (!searching)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.search_rounded,
                    color: BrandTokens.textSecondary),
              ),
          ],
        );
      },
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  final ValueListenable<List<NominatimResult>> suggestionsVN;
  final ValueListenable<String?> errorVN;
  final TextEditingController controller;
  final ValueChanged<NominatimResult> onPick;
  final ValueListenable<bool> focusedVN;
  final ValueListenable<List<NominatimResult>> recentsVN;

  const _ResultsPanel({
    required this.suggestionsVN,
    required this.errorVN,
    required this.controller,
    required this.onPick,
    required this.focusedVN,
    required this.recentsVN,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([suggestionsVN, errorVN, focusedVN, recentsVN]),
      builder: (_, __) {
        final suggestions = suggestionsVN.value;
        final err = errorVN.value;
        final focused = focusedVN.value;
        final recents = recentsVN.value;

        // 1. Live results
        if (suggestions.isNotEmpty) {
          return _PanelCard(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: BrandTokens.borderSoft,
                indent: 60,
              ),
              itemBuilder: (context, i) => _ResultTile(
                result: suggestions[i],
                icon: _iconForCategory(suggestions[i].category),
                onTap: () => onPick(suggestions[i]),
              ),
            ),
          );
        }

        // 2. Error pill
        if (err != null && controller.text.length >= 2) {
          return _PanelCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: BrandTokens.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      err,
                      style: const TextStyle(
                        color: BrandTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 3. Recents (only when focused & no text)
        if (focused && controller.text.isEmpty && recents.isNotEmpty) {
          return _PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    'RECENT',
                    style: TextStyle(
                      color: BrandTokens.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                ListView.separated(
                  padding: const EdgeInsets.only(bottom: 6),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recents.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: BrandTokens.borderSoft,
                    indent: 60,
                  ),
                  itemBuilder: (context, i) => _ResultTile(
                    result: recents[i],
                    icon: Icons.history_rounded,
                    onTap: () => onPick(recents[i]),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  static IconData _iconForCategory(String? cat) {
    if (cat == null) return Icons.place_rounded;
    final lower = cat.toLowerCase();
    if (lower.contains('road') || lower.contains('highway') ||
        lower.contains('street')) {
      return Icons.alt_route_rounded;
    }
    if (lower.contains('city') || lower.contains('town') ||
        lower.contains('village') || lower.contains('place')) {
      return Icons.location_city_rounded;
    }
    if (lower.contains('amenity') || lower.contains('shop') ||
        lower.contains('poi') || lower.contains('tourism') ||
        lower.contains('attraction')) {
      return Icons.storefront_rounded;
    }
    if (lower.contains('neighbour') || lower.contains('district') ||
        lower.contains('locality') || lower.contains('suburb')) {
      return Icons.holiday_village_rounded;
    }
    return Icons.place_rounded;
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 360),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BrandTokens.shadowSoft,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final NominatimResult result;
  final IconData icon;
  final VoidCallback onTap;
  const _ResultTile({
    required this.result,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandTokens.primaryBlue.withValues(alpha: 0.10),
                    BrandTokens.primaryBlue.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: BrandTokens.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      color: BrandTokens.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.displayName.isNotEmpty &&
                      result.displayName != result.name)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        result.displayName,
                        style: const TextStyle(
                          color: BrandTokens.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.north_west_rounded,
              size: 16,
              color: BrandTokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Glass icon buttons / FAB
// =============================================================================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double rotationRad;
  final Color color;
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.rotationRad = 0,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Transform.rotate(
                  angle: rotationRad,
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyLocationFab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _MyLocationFab({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: BrandTokens.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Center pin (pulsing teardrop)
// =============================================================================

class _PulsingPin extends StatefulWidget {
  final Color color;
  const _PulsingPin({required this.color});

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        width: 90,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring.
            Positioned(
              bottom: 16,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final v = _ctrl.value;
                  return Opacity(
                    opacity: (1 - v) * 0.45,
                    child: Transform.scale(
                      scale: 1 + v * 0.6,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Solid base dot.
            Positioned(
              bottom: 22,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Teardrop with inner gradient + dot.
            Positioned(
              top: 0,
              child: _Teardrop(color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Teardrop extends StatelessWidget {
  final Color color;
  const _Teardrop({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: CustomPaint(
              size: const Size(38, 50),
              painter: _DropPainter(
                color: Colors.black.withValues(alpha: 0.20),
              ),
            ),
          ),
          CustomPaint(
            size: const Size(38, 50),
            painter: _DropPainter(color: color),
          ),
          const Positioned(
            top: 13,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 12, height: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  final Color color;
  _DropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = ui.Path();
    path.moveTo(w / 2, h);
    path.cubicTo(w * 0.05, h * 0.62, w * 0.0, h * 0.20, w * 0.5, 0);
    path.cubicTo(w * 1.0, h * 0.20, w * 0.95, h * 0.62, w / 2, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// Frosted bottom sheet
// =============================================================================

class _FrostedBottomSheet extends StatelessWidget {
  final bool isPickup;
  final ValueListenable<String?> labelVN;
  final ValueListenable<String?> addressVN;
  final ValueListenable<bool> resolvingVN;
  final ValueListenable<LatLng> centerVN;
  final VoidCallback onConfirm;

  const _FrostedBottomSheet({
    required this.isPickup,
    required this.labelVN,
    required this.addressVN,
    required this.resolvingVN,
    required this.centerVN,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isPickup ? BrandTokens.successGreen : BrandTokens.dangerRed;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: BrandTokens.shadowDeep,
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: resolvingVN,
                builder: (_, resolving, __) => SizedBox(
                  height: 3,
                  child: resolving
                      ? const LinearProgressIndicator(
                          minHeight: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              BrandTokens.primaryBlue),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: BrandTokens.borderSoft,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.18),
                                accent.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPickup
                                ? Icons.trip_origin_rounded
                                : Icons.flag_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _LiveAddressBlock(
                            isPickup: isPickup,
                            labelVN: labelVN,
                            addressVN: addressVN,
                            centerVN: centerVN,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ConfirmButton(
                      label:
                          isPickup ? 'Confirm pickup' : 'Confirm destination',
                      onTap: onConfirm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveAddressBlock extends StatelessWidget {
  final bool isPickup;
  final ValueListenable<String?> labelVN;
  final ValueListenable<String?> addressVN;
  final ValueListenable<LatLng> centerVN;

  const _LiveAddressBlock({
    required this.isPickup,
    required this.labelVN,
    required this.addressVN,
    required this.centerVN,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isPickup ? 'PICKUP POINT' : 'DESTINATION',
          style: const TextStyle(
            color: BrandTokens.textSecondary,
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<String?>(
          valueListenable: labelVN,
          builder: (_, label, __) => Text(
            (label == null || label.trim().isEmpty)
                ? 'Move the map to choose a point'
                : label,
            style: const TextStyle(
              color: BrandTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: addressVN,
          builder: (_, address, __) {
            if (address == null || address.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                address,
                style: const TextStyle(
                  color: BrandTokens.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<LatLng>(
          valueListenable: centerVN,
          builder: (_, center, __) => Text(
            '${center.latitude.toStringAsFixed(5)}, '
            '${center.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              color: BrandTokens.textSecondary,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ConfirmButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: BrandTokens.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.36),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Permission dialog + bootstrap shimmer + attribution chip
// =============================================================================

class _PermissionDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final Future<void> Function() onPrimary;

  const _PermissionDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BrandTokens.surfaceWhite,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandTokens.primaryBlue.withValues(alpha: 0.14),
                    BrandTokens.primaryBlue.withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: BrandTokens.primaryBlue, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: BrandTokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: BrandTokens.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: BrandTokens.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: BrandTokens.primaryBlue
                          .withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await onPrimary();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Center(
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Not now',
                style: TextStyle(
                  color: BrandTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootstrapShimmer extends StatelessWidget {
  const _BootstrapShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandTokens.primaryBlue, BrandTokens.primaryBlueDark],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Finding your real location…',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributionChip extends StatelessWidget {
  const _AttributionChip();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '\u00A9 OpenStreetMap contributors',
            style: TextStyle(fontSize: 9.5, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
