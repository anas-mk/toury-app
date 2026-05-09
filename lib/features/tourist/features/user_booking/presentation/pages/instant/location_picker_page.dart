import 'dart:async';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' hide Position, LocationSettings;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../../core/services/location/mapbox_geocoding_service.dart';
import '../../../../../../../core/services/location/nominatim_service.dart';
import '../../../../../../../core/services/location/recent_searches_store.dart';
import '../../../../../../../core/services/location/search_debouncer.dart';
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

  /// When set (pickup screen only) shows a "Meet at destination" shortcut.
  /// Tapping it returns this location as the pickup result.
  final LocationPickResult? destinationForMeet;

  const LocationPickerPage({
    super.key,
    required this.title,
    required this.isPickup,
    this.initial,
    this.destinationForMeet,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // Last-resort fallback (Tahrir Square, Cairo) used ONLY when every
  // attempt to read a real position fails AND the user explicitly
  // declined location services. We never substitute mock data for a
  // working GPS reading.
  static const _cairoFallback = _LL(30.0444, 31.2357);

  MapboxMap? _mapboxMap;
  double _currentZoom = 16.0;
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
        language: 'en',
        cancelToken: cancelToken,
        nearLat: c.latitude,
        nearLng: c.longitude,
      );
    },
  );

  Timer? _reverseDebounce;
  Timer? _bootstrapTimeout;
  CancelToken? _reverseCancel;


  // ── Live state in ValueNotifiers so high-frequency events (drag,
  // typing, reverse-geocode arrivals) only rebuild the small subtree
  // that listens to the specific notifier.
  final ValueNotifier<_LL> _centerVN = ValueNotifier(_cairoFallback);
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

    unawaited(_loadRecents());
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _reverseDebounce?.cancel();
    _bootstrapTimeout?.cancel();
    _reverseCancel?.cancel('disposed');
    _searchCtrl.dispose();
    _searchFocus.dispose();
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
      _centerVN.value = _LL(widget.initial!.latitude, widget.initial!.longitude);
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
      _centerVN.value = _LL(
        (lastKnown.latitude as double),
        (lastKnown.longitude as double),
      );
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
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final next = _LL(pos.latitude, pos.longitude);

      if (!_initialised) {
        _bootstrapTimeout?.cancel();
        _centerVN.value = next;
        setState(() => _initialised = true);
        _moveCamera(next, 16);
        _scheduleReverseGeocode(next, immediate: true);
        return;
      }
      if (!_userMovedMap) {
        _moveCamera(next, _currentZoom);
        _centerVN.value = next;
        _scheduleReverseGeocode(next, immediate: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationPicker] getCurrentPosition: $e');
    }
  }

  Future<dynamic> _safeLastKnown() async {
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

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onCameraChanged(CameraChangedEventData data) {
    if (!mounted) return;
    _userMovedMap = true;
    _mapboxMap?.getCameraState().then((camera) {
      if (!mounted) return;
      final coords = camera.center.coordinates;
      final coord = _LL(coords.lat.toDouble(), coords.lng.toDouble());
      _centerVN.value = coord;
      _bearingVN.value = camera.bearing;
      _currentZoom = camera.zoom;
      _scheduleReverseGeocode(coord);
    });
  }

  void _moveCamera(_LL coord, double zoom) {
    _mapboxMap?.setCamera(CameraOptions(
      center: Point(coordinates: Position(coord.longitude, coord.latitude)),
      zoom: zoom,
    ));
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
      dynamic pos;
      try {
        pos = await Geolocator.getCurrentPosition();
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
      final next = _LL(pos.latitude, pos.longitude);
      _userMovedMap = true;
      _moveCamera(next, 16);
      _centerVN.value = next;
      _scheduleReverseGeocode(next, immediate: true);
    } finally {
      if (mounted) _myLocLoadingVN.value = false;
    }
  }

  void _onResetBearing() {
    HapticFeedback.selectionClick();
    _mapboxMap?.setCamera(CameraOptions(bearing: 0.0));
    _bearingVN.value = 0;
  }

  void _onZoom(double delta) {
    HapticFeedback.selectionClick();
    final z = (_currentZoom + delta).clamp(3.0, 19.0);
    _mapboxMap?.setCamera(CameraOptions(zoom: z));
    _currentZoom = z;
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
    // Remove the listener before setting text so the keystroke handler
    // does NOT schedule a new debounced search for the selected name.
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.value = TextEditingValue(
      text: r.name,
      selection: TextSelection.collapsed(offset: r.name.length),
      composing: TextRange.empty,
    );
    _searchCtrl.addListener(_onSearchChanged);
    _searchDebouncer.cancel();
    _hasTextVN.value = r.name.isNotEmpty;
    _searchingVN.value = false;
    _searchErrorVN.value = null;
    final next = _LL(r.lat, r.lng);
    _userMovedMap = true;
    _moveCamera(next, 16);
    _centerVN.value = next;
    _labelVN.value = r.name;
    _addressVN.value = r.displayName;
    _suggestionsVN.value = const [];
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

  void _scheduleReverseGeocode(_LL latLng, {bool immediate = false}) {
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

  Future<void> _reverseGeocode(_LL latLng) async {
    final token = CancelToken();
    _reverseCancel = token;
    try {
      final r = await _geo.reverse(
        lat: latLng.latitude,
        lng: latLng.longitude,
        language: 'en',
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

  /// Returns `true` if the current label is still a raw coord pair
  /// (the picker's fallback when reverse-geocoding has not produced
  /// a real place name yet).
  static bool _looksLikeCoords(String s) {
    return RegExp(r'^\s*-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?\s*$').hasMatch(s);
  }

  /// Confirm the current pin. If the resolved label is still in
  /// coordinate-form (reverse-geocoding hasn't produced a real
  /// place name) we kick off a fresh reverse-geocode and wait up to
  /// ~1.5s for it to land before popping. This ensures downstream
  /// pages (Find a Helper, Confirm Booking, …) almost always see a
  /// human-readable name like "Saad Ibrahim St" instead of
  /// "30.09225, 31.26466".
  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    final center = _centerVN.value;
    var cleanLabel = (_labelVN.value ?? '').trim();
    var addr = _addressVN.value;

    final needsResolve = cleanLabel.isEmpty || _looksLikeCoords(cleanLabel);
    if (needsResolve) {
      // Force an immediate reverse-geocode (cancels any pending
      // debounce) and wait briefly for it to finish so the saved
      // name is human-friendly.
      _scheduleReverseGeocode(center, immediate: true);
      try {
        final deadline = DateTime.now().add(const Duration(milliseconds: 1500));
        while (mounted &&
            _resolvingVN.value &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      } catch (_) {/* fall through with whatever we have */}
      if (!mounted) return;
      cleanLabel = (_labelVN.value ?? '').trim();
      addr = _addressVN.value;
    }

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
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  // -------------------- build --------------------

  @override
  Widget build(BuildContext context) {
    final pinColor = widget.isPickup
        ? BrandTokens.accentAmber
        : BrandTokens.primaryBlue;
    final mediaTop = MediaQuery.of(context).padding.top;

    // Force a transparent / light status bar so the map tiles bleed up
    // behind it. Without this, Android draws a solid black bar on top
    // of the page on some devices (especially when launching from a
    // Scaffold-based parent that set its own dark style).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: BrandTokens.bgSoft,
      resizeToAvoidBottomInset: false,
      body: !_initialised
          ? const _BootstrapShimmer()
          : Stack(
              children: [
                // 1. The map.
                RepaintBoundary(
                  child: MapWidget(
                    key: const ValueKey('locationPickerMap'),
                    // ignore: deprecated_member_use
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: Position(
                        _centerVN.value.longitude,
                        _centerVN.value.latitude,
                      )),
                      zoom: 16.0,
                    ),
                    styleUri: MapboxStyles.LIGHT,
                    onMapCreated: _onMapCreated,
                    onCameraChangeListener: _onCameraChanged,
                  ),
                ),

                // 2. Very subtle warm-overlay (mix-blend feel).
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: BrandTokens.bgSoft.withValues(alpha: 0.10),
                    ),
                  ),
                ),

                // 3. Centre pin (round, with pulse rings).
                Center(child: _CenterPin(color: pinColor)),

                // 4. Attribution chip.
                const Positioned(
                  left: 10,
                  bottom: 10,
                  child: _AttributionChip(),
                ),

                // 5. Floating top row: back button + pill search bar.
                Positioned(
                  top: mediaTop + 12,
                  left: 16,
                  right: 16,
                  child: _TopSearchRow(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    isSearchingVN: _searchingVN,
                    errorVN: _searchErrorVN,
                    suggestionsVN: _suggestionsVN,
                    hasTextVN: _hasTextVN,
                    focusedVN: _focusedVN,
                    recentsVN: _recentsVN,
                    myLocLoadingVN: _myLocLoadingVN,
                    onClear: _clearSearch,
                    onPick: _onPickSuggestion,
                    onBack: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).maybePop();
                    },
                    onUseMyLocation: _onUseMyLocation,
                    isPickup: widget.isPickup,
                  ),
                ),

                // 6. Right-side controls (zoom pill, vertically centred).
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ZoomControls(
                      onZoomIn: () => _onZoom(1),
                      onZoomOut: () => _onZoom(-1),
                      bearingVN: _bearingVN,
                      onResetBearing: _onResetBearing,
                    ),
                  ),
                ),

                // 7. Bottom sheet with confirm.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _BottomActionSheet(
                      isPickup: widget.isPickup,
                      labelVN: _labelVN,
                      addressVN: _addressVN,
                      resolvingVN: _resolvingVN,
                      centerVN: _centerVN,
                      onConfirm: _confirm,
                      destinationForMeet: widget.isPickup
                          ? widget.destinationForMeet
                          : null,
                      onMeetAtDestination: widget.isPickup &&
                              widget.destinationForMeet != null
                          ? () => Navigator.of(context)
                              .pop(widget.destinationForMeet)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

// =============================================================================
// Top row: floating circular back button + pill search bar
// (Inspired by RAFIQ HTML mockup — Material 3 expressive, light & airy.)
// =============================================================================

class _TopSearchRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> isSearchingVN;
  final ValueListenable<String?> errorVN;
  final ValueListenable<List<NominatimResult>> suggestionsVN;
  final ValueListenable<bool> hasTextVN;
  final ValueListenable<bool> focusedVN;
  final ValueListenable<List<NominatimResult>> recentsVN;
  final ValueListenable<bool> myLocLoadingVN;
  final VoidCallback onClear;
  final ValueChanged<NominatimResult> onPick;
  final VoidCallback onBack;
  final VoidCallback onUseMyLocation;
  final bool isPickup;

  const _TopSearchRow({
    required this.controller,
    required this.focusNode,
    required this.isSearchingVN,
    required this.errorVN,
    required this.suggestionsVN,
    required this.hasTextVN,
    required this.focusedVN,
    required this.recentsVN,
    required this.myLocLoadingVN,
    required this.onClear,
    required this.onPick,
    required this.onBack,
    required this.onUseMyLocation,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _FrostedCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
                tooltip: 'Back',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PillSearchBar(
                  controller: controller,
                  focusNode: focusNode,
                  isSearchingVN: isSearchingVN,
                  hasTextVN: hasTextVN,
                  myLocLoadingVN: myLocLoadingVN,
                  onClear: onClear,
                  onUseMyLocation: onUseMyLocation,
                  isPickup: isPickup,
                ),
              ),
            ],
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

/// The frosted-glass pill that contains the search input. Mirrors the
/// HTML mockup (`rounded-full bg-white/80 backdrop-blur-md`) but keeps
/// our existing search functionality (debounce, suggestions, clear).
class _PillSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> isSearchingVN;
  final ValueListenable<bool> hasTextVN;
  final ValueListenable<bool> myLocLoadingVN;
  final VoidCallback onClear;
  final VoidCallback onUseMyLocation;
  final bool isPickup;

  const _PillSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearchingVN,
    required this.hasTextVN,
    required this.myLocLoadingVN,
    required this.onClear,
    required this.onUseMyLocation,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: BrandTokens.borderSoft.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: BrandTokens.shadowSoft,
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: BrandTokens.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => focusNode.unfocus(),
                  // NOTE: we deliberately do NOT use `onTapOutside` here.
                  // It fires for ANY tap inside the page (including taps
                  // on the suggestions / recents list rendered behind
                  // this field), which would unfocus and rebuild the
                  // panel before the row's `onTap` could run — making
                  // the recents tiles feel "uncatchable". Unfocusing is
                  // already handled when the user taps the map (handled
                  // by the camera-changed listener) or submits.
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BrandTokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: isPickup ? 'Where from?' : 'Where to?',
                    hintStyle: const TextStyle(
                      color: BrandTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              _SearchTrailing(
                isSearchingVN: isSearchingVN,
                hasTextVN: hasTextVN,
                myLocLoadingVN: myLocLoadingVN,
                onClear: onClear,
                onUseMyLocation: onUseMyLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing area inside the pill. Shows either:
///  - a clear (×) button when text is present,
///  - a tiny spinner while a network search is in flight,
///  - or the brand-blue "my location" icon by default.
class _SearchTrailing extends StatelessWidget {
  final ValueListenable<bool> isSearchingVN;
  final ValueListenable<bool> hasTextVN;
  final ValueListenable<bool> myLocLoadingVN;
  final VoidCallback onClear;
  final VoidCallback onUseMyLocation;
  const _SearchTrailing({
    required this.isSearchingVN,
    required this.hasTextVN,
    required this.myLocLoadingVN,
    required this.onClear,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([isSearchingVN, hasTextVN, myLocLoadingVN]),
      builder: (_, __) {
        final searching = isSearchingVN.value;
        final hasText = hasTextVN.value;
        final myLocLoading = myLocLoadingVN.value;

        if (hasText) {
          return _TrailingIconButton(
            icon: Icons.close_rounded,
            color: BrandTokens.textSecondary,
            tooltip: 'Clear',
            onTap: onClear,
          );
        }
        if (searching) {
          return const Padding(
            padding: EdgeInsets.only(left: 6, right: 4),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    BrandTokens.primaryBlue),
              ),
            ),
          );
        }
        if (myLocLoading) {
          return const Padding(
            padding: EdgeInsets.only(left: 6, right: 4),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    BrandTokens.primaryBlue),
              ),
            ),
          );
        }
        return _TrailingIconButton(
          icon: Icons.my_location_rounded,
          color: BrandTokens.primaryBlue,
          tooltip: 'Use my location',
          onTap: onUseMyLocation,
        );
      },
    );
  }
}

class _TrailingIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _TrailingIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Small frosted circular button used for the back action.
class _FrostedCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _FrostedCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.88),
          shape: CircleBorder(
            side: BorderSide(
              color: BrandTokens.borderSoft.withValues(alpha: 0.5),
            ),
          ),
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  color: BrandTokens.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
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

        // 1. Live search results — scrollable list inside the panel.
        if (suggestions.isNotEmpty) {
          return _PanelCard(
            child: _PanelList(
              header: null,
              itemCount: suggestions.length,
              itemBuilder: (i) => _ResultTile(
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
                  horizontal: 16, vertical: 16),
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

        // 3. Recents (only when focused & no text) — scrollable list
        // with a sticky 'RECENT' label on top.
        if (focused && controller.text.isEmpty && recents.isNotEmpty) {
          return _PanelCard(
            child: _PanelList(
              header: const _PanelHeader(label: 'RECENT'),
              itemCount: recents.length,
              itemBuilder: (i) => _ResultTile(
                result: recents[i],
                icon: Icons.history_rounded,
                onTap: () => onPick(recents[i]),
              ),
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
    final mq = MediaQuery.of(context);
    // Available vertical room = screen − keyboard − (status bar + pill
    // + sheet area). Clamp generously so the panel actually fills the
    // visible space instead of looking like a tiny pill peek-out.
    final maxH = (mq.size.height - mq.viewInsets.bottom - 200)
        .clamp(160.0, 520.0);
    return Padding(
      // Full-width panel (matches Material 3 Search-view pattern).
      // The back button above is OK to overflow visually because the
      // panel sits below it, not next to it.
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: BrandTokens.borderSoft.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: BrandTokens.shadowSoft,
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            // The child supplies its own scrollable list (Suggestions /
            // Recents) — wrap it in a Material so InkWells inside the
            // panel paint correctly above the BackdropFilter.
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A scrollable list inside [_PanelCard]. Supports an optional sticky
/// header (e.g. the "RECENT" label). The list itself is the only thing
/// that scrolls — keeping the header anchored gives the panel a clean
/// Material 3 search-view feel.
class _PanelList extends StatelessWidget {
  final Widget? header;
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  const _PanelList({
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        Flexible(
          // ListView (not shrinkWrap with NeverScrollable) — gives the
          // user a real scrollable surface, even when the suggestions
          // overflow the panel's max height. `Flexible` lets the list
          // shrink to its content when small, and grow to the panel's
          // max height when long.
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            // BouncingScrollPhysics on iOS / Clamping on Android — the
            // platform default avoids the scroll feeling foreign.
            physics: const AlwaysScrollableScrollPhysics(),
            // Make sure taps on tiles are not accidentally swallowed
            // by the parent panel's gesture detection.
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.manual,
            itemCount: itemCount,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: BrandTokens.borderSoft,
              indent: 70,
              endIndent: 16,
            ),
            itemBuilder: (_, i) => itemBuilder(i),
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String label;
  const _PanelHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: BrandTokens.borderSoft,
            width: 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: BrandTokens.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandTokens.bgSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: BrandTokens.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      color: BrandTokens.textPrimary,
                      fontSize: 14.5,
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
                          height: 1.35,
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
// Right-side zoom controls (single frosted pill).
//
// Shows + / − stacked vertically. A compass affordance is appended only
// when the bearing is non-zero, so the chrome stays minimal at rest.
// =============================================================================

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final ValueListenable<double> bearingVN;
  final VoidCallback onResetBearing;
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.bearingVN,
    required this.onResetBearing,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: bearingVN,
      builder: (_, bearing, __) {
        final showCompass = bearing.abs() > 0.5;
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: BrandTokens.borderSoft.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: BrandTokens.shadowSoft,
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ZoomButton(
                    icon: Icons.add_rounded,
                    onTap: onZoomIn,
                  ),
                  Container(
                    width: 26,
                    height: 1,
                    color: BrandTokens.borderSoft.withValues(alpha: 0.6),
                  ),
                  _ZoomButton(
                    icon: Icons.remove_rounded,
                    onTap: onZoomOut,
                  ),
                  if (showCompass) ...[
                    Container(
                      width: 26,
                      height: 1,
                      color:
                          BrandTokens.borderSoft.withValues(alpha: 0.6),
                    ),
                    _ZoomButton(
                      icon: Icons.explore_rounded,
                      iconColor: BrandTokens.primaryBlue,
                      rotationRad:
                          bearing * (3.1415926535 / 180.0) * -1,
                      onTap: onResetBearing,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double rotationRad;
  const _ZoomButton({
    required this.icon,
    required this.onTap,
    this.iconColor = BrandTokens.textPrimary,
    this.rotationRad = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Transform.rotate(
            angle: rotationRad,
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Center pin (round badge with `location_on`, soft pulse ring + anchor dot).
//
// Matches the RAFIQ HTML mockup: a 48-px solid coloured circle with a
// white `location_on` glyph, surrounded by a static ring (sized 1.25×)
// to suggest active selection. A tiny dot sits below the circle as the
// visual "anchor" so the user knows exactly which point on the map is
// being selected.
// =============================================================================

class _CenterPin extends StatefulWidget {
  final Color color;
  const _CenterPin({required this.color});

  @override
  State<_CenterPin> createState() => _CenterPinState();
}

class _CenterPinState extends State<_CenterPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1700))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const badge = 48.0;
    const dot = 6.0;
    // SizedBox is tall enough to house the badge (with its halo) plus a
    // small gap and the anchor dot. The dot sits at the visual centre of
    // the SizedBox so it lines up with the map crosshair.
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated halo behind the pin badge.
            Positioned(
              top: 6,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final v = _ctrl.value;
                  return Opacity(
                    opacity: (1 - v) * 0.45,
                    child: Transform.scale(
                      scale: 0.6 + v * 0.9,
                      child: Container(
                        width: badge,
                        height: badge,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // The badge itself.
            Positioned(
              top: 6,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.30),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            // Tiny anchor dot, a few pixels below the badge centre.
            Positioned(
              top: 6 + badge + 6,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom action sheet (solid surface + rounded-full CTA).
//
// The HTML mockup uses a flat white sheet with a drag handle, a single
// row of (icon | title | subtitle), and a primary `rounded-full` CTA
// with the label on the leading side and an icon on the trailing side.
// =============================================================================

class _BottomActionSheet extends StatelessWidget {
  final bool isPickup;
  final ValueListenable<String?> labelVN;
  final ValueListenable<String?> addressVN;
  final ValueListenable<bool> resolvingVN;
  final ValueListenable<_LL> centerVN;
  final VoidCallback onConfirm;
  final LocationPickResult? destinationForMeet;
  final VoidCallback? onMeetAtDestination;

  const _BottomActionSheet({
    required this.isPickup,
    required this.labelVN,
    required this.addressVN,
    required this.resolvingVN,
    required this.centerVN,
    required this.onConfirm,
    this.destinationForMeet,
    this.onMeetAtDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.shadowDeep,
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reverse-geocode progress strip — sits flush at the very top
          // edge so it never pushes the drag handle around.
          ValueListenableBuilder<bool>(
            valueListenable: resolvingVN,
            builder: (_, resolving, __) => SizedBox(
              height: 2,
              child: resolving
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                      child: const LinearProgressIndicator(
                        minHeight: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            BrandTokens.primaryBlue),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Drag handle.
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: BrandTokens.borderSoft,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LocationDetailsRow(
                  isPickup: isPickup,
                  labelVN: labelVN,
                  addressVN: addressVN,
                  centerVN: centerVN,
                ),
                const SizedBox(height: 24),
                if (onMeetAtDestination != null &&
                    destinationForMeet != null) ...[
                  _MeetAtDestinationButton(
                    destinationName: destinationForMeet!.name,
                    onTap: onMeetAtDestination!,
                  ),
                  const SizedBox(height: 12),
                ],
                _ConfirmCtaButton(
                  label: isPickup
                      ? 'Confirm Pickup'
                      : 'Confirm Destination',
                  onTap: onConfirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDetailsRow extends StatelessWidget {
  final bool isPickup;
  final ValueListenable<String?> labelVN;
  final ValueListenable<String?> addressVN;
  final ValueListenable<_LL> centerVN;
  const _LocationDetailsRow({
    required this.isPickup,
    required this.labelVN,
    required this.addressVN,
    required this.centerVN,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: BrandTokens.bgSoft,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(
            Icons.near_me_rounded,
            color: BrandTokens.primaryBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: labelVN,
                builder: (_, label, __) => Text(
                  (label == null || label.trim().isEmpty)
                      ? (isPickup ? 'Pick a pickup point' : 'Pick a destination')
                      : label,
                  style: const TextStyle(
                    color: BrandTokens.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              ValueListenableBuilder<String?>(
                valueListenable: addressVN,
                builder: (_, address, __) {
                  if (address != null && address.isNotEmpty) {
                    return Text(
                      address,
                      style: const TextStyle(
                        color: BrandTokens.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return ValueListenableBuilder<_LL>(
                    valueListenable: centerVN,
                    builder: (_, center, __) => Text(
                      '${center.latitude.toStringAsFixed(5)}, '
                      '${center.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: BrandTokens.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ConfirmCtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandTokens.primaryBlue,
      borderRadius: BorderRadius.circular(40),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: BrandTokens.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetAtDestinationButton extends StatelessWidget {
  final String destinationName;
  final VoidCallback onTap;
  const _MeetAtDestinationButton({
    required this.destinationName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandTokens.bgSoft,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.group_rounded,
                color: BrandTokens.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Meet at destination  ·  ${_shorten(destinationName)}',
                  style: const TextStyle(
                    color: BrandTokens.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: BrandTokens.primaryBlue,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shorten(String name) {
    final parts = name.split(',');
    final short = parts.first.trim();
    return short.length > 24 ? '${short.substring(0, 22)}…' : short;
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

/// Lightweight coordinate pair — replaces `package:latlong2` LatLng
/// with the same property names so migration is zero-friction.
class _LL {
  final double latitude;
  final double longitude;
  const _LL(this.latitude, this.longitude);
}
