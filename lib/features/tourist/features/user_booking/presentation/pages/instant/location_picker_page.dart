import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../../../core/services/location/nominatim_service.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import 'location_pick_result.dart';

/// Fullscreen map picker shared by Pickup + Destination steps.
///
/// Pass #2 hard requirements implemented here:
///   - Page opens centred on the user's GPS (with permission flow + fallback).
///   - Floating search bar at the top backed by Nominatim, debounced 350ms,
///     with cancellation of stale requests.
///   - Carto Voyager tiles, maxZoom 19, minZoom 3.
///   - Pulsing teardrop pin (color depends on pickup vs destination).
///   - Compass badge top-right (resets bearing on tap).
///   - My-location FAB bottom-right above the sticky bottom sheet.
///   - Sticky bottom sheet with reverse-geocoded address (debounced 400ms
///     on MapEventMoveEnd) and a primary "Confirm" button.
///   - Returns `LocationPickResult` whose `name` is never empty.
class LocationPickerPage extends StatefulWidget {
  /// Title shown at the top of the picker (e.g. "Pickup point").
  final String title;

  /// `true` for the pickup screen, `false` for the destination screen.
  /// Controls accent colour of the pin and CTA copy.
  final bool isPickup;

  /// Optional initial position. If `null`, we try the device's current
  /// location, falling back to a generic city view.
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
  // Last-resort fallback used ONLY when every attempt to read a position
  // (last-known + current + permissions) has failed. We never override what
  // the device actually reports — emulator users wanting to test a real
  // location should set it via Android Studio → Extended Controls → Location.
  static const _cairoFallback = LatLng(30.0444, 31.2357);

  final MapController _mapController = MapController();
  final NominatimService _nominatim = NominatimService();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _searchDebounce;
  Timer? _reverseDebounce;
  Timer? _bootstrapTimeout;
  CancelToken? _searchCancel;
  CancelToken? _reverseCancel;
  StreamSubscription<MapEvent>? _mapEventsSub;

  // ── Live state. All transient state is held in ValueNotifiers (not
  // setState fields) so that high-frequency events (drag, search keystrokes,
  // reverse-geocode results) only rebuild the small subtree that listens to
  // the specific notifier — never the whole Scaffold/FlutterMap tree. This
  // is the single most important change for the "app hangs while typing /
  // dragging" complaint.
  final ValueNotifier<LatLng> _centerVN = ValueNotifier(_cairoFallback);
  final ValueNotifier<double> _bearingVN = ValueNotifier(0);
  final ValueNotifier<String?> _labelVN = ValueNotifier(null);
  final ValueNotifier<String?> _addressVN = ValueNotifier(null);
  final ValueNotifier<bool> _resolvingVN = ValueNotifier(false);
  // Search-related transient state.
  final ValueNotifier<bool> _searchingVN = ValueNotifier(false);
  final ValueNotifier<String?> _searchErrorVN = ValueNotifier(null);
  final ValueNotifier<List<NominatimResult>> _suggestionsVN =
      ValueNotifier(const []);
  final ValueNotifier<bool> _hasTextVN = ValueNotifier(false);
  // Misc UI flags.
  final ValueNotifier<bool> _myLocLoadingVN = ValueNotifier(false);
  final ValueNotifier<bool> _showShimmerVN = ValueNotifier(true);

  bool _initialised = false;
  // Once the user pans/zooms or searches, we stop auto-following any later
  // higher-accuracy GPS fix that arrives in the background.
  bool _userMovedMap = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _bootstrap();
    _mapEventsSub = _mapController.mapEventStream.listen(_onMapEvent);
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _showShimmerVN.value = false;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _bootstrapTimeout?.cancel();
    _searchCancel?.cancel('disposed');
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
    _showShimmerVN.dispose();
    super.dispose();
  }

  // -------------------- bootstrap & permissions --------------------

  /// Two-stage GPS bootstrap so the page renders ASAP:
  /// 1. Read the OS's cached `getLastKnownPosition` (returns near-instantly)
  ///    and render the map at that pin straight away.
  /// 2. In the background, request a fresh high-accuracy fix; once it
  ///    arrives, gently slide the map there if the user hasn't started
  ///    picking yet.
  ///
  /// We never substitute "real" GPS readings for a hard-coded fallback — if
  /// the device reports somewhere in California (e.g. an unconfigured
  /// emulator) that's exactly what we show, because lying to the user about
  /// their location is much worse than showing the unedited truth. The
  /// Cairo fallback is only used if BOTH calls return null.
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

    await _ensurePermissions();

    final lastKnown = await _safeLastKnown();
    if (!mounted) return;
    if (lastKnown != null) {
      _centerVN.value = LatLng(lastKnown.latitude, lastKnown.longitude);
      setState(() => _initialised = true);
      _scheduleReverseGeocode(_centerVN.value, immediate: true);
    }

    unawaited(_fetchAndApplyCurrentPosition());

    _bootstrapTimeout = Timer(const Duration(seconds: 6), () {
      if (!mounted || _initialised) return;
      _centerVN.value = _cairoFallback;
      setState(() => _initialised = true);
      _scheduleReverseGeocode(_cairoFallback, immediate: true);
      _showLocationDeniedSnack();
    });
  }

  Future<void> _ensurePermissions() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('[LocationPicker] permission check failed: $e');
    }
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
        _scheduleReverseGeocode(next, immediate: true);
        return;
      }
      if (!_userMovedMap) {
        _mapController.move(next, _mapController.camera.zoom);
        _centerVN.value = next;
        _scheduleReverseGeocode(next, immediate: true);
      }
    } catch (e) {
      debugPrint('[LocationPicker] getCurrentPosition failed: $e');
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

  /// Strategy: do nothing during continuous events (drag, zoom-in-progress,
  /// rotate-in-progress) other than tracking the live bearing for the
  /// compass needle. All real work — coordinate snapshot, reverse geocode,
  /// "user moved map" flag — happens only when the gesture ENDS. This keeps
  /// the per-frame work during a drag at zero notifier writes, which is
  /// what eliminates the perceived hang.
  void _onMapEvent(MapEvent event) {
    if (!mounted) return;
    if (event is MapEventRotate) {
      _bearingVN.value = event.camera.rotation;
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
    _myLocLoadingVN.value = true;
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isPermanentlyDenied || status.isDenied) {
        if (!mounted) return;
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
      _mapController.move(next, 16);
      _centerVN.value = next;
      _scheduleReverseGeocode(next, immediate: true);
    } finally {
      if (mounted) _myLocLoadingVN.value = false;
    }
  }

  void _onResetBearing() {
    _mapController.rotate(0);
    _bearingVN.value = 0;
  }

  // -------------------- search (Nominatim) --------------------

  void _onSearchChanged() {
    final raw = _searchCtrl.text;
    final hasText = raw.isNotEmpty;
    if (_hasTextVN.value != hasText) _hasTextVN.value = hasText;
    final value = raw.trim();
    _searchDebounce?.cancel();
    if (value.length < 2) {
      _searchCancel?.cancel('typing');
      _suggestionsVN.value = const [];
      _searchingVN.value = false;
      _searchErrorVN.value = null;
      return;
    }
    _searchDebounce =
        Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    _searchCancel?.cancel('superseded');
    final token = CancelToken();
    _searchCancel = token;
    _searchingVN.value = true;
    _searchErrorVN.value = null;
    try {
      final results = await _nominatim.search(
        query: query,
        limit: 6,
        cancelToken: token,
        acceptLanguage: 'en',
      );
      if (!mounted || token.isCancelled) return;
      _suggestionsVN.value = results;
      _searchingVN.value = false;
      _searchErrorVN.value = results.isEmpty ? 'No results' : null;
    } catch (_) {
      if (!mounted || token.isCancelled) return;
      _suggestionsVN.value = const [];
      _searchingVN.value = false;
      _searchErrorVN.value = 'Search failed. Try again.';
    }
  }

  void _onPickSuggestion(NominatimResult r) {
    _searchFocus.unfocus();
    _searchCtrl.text = r.name;
    _searchCtrl.selection = TextSelection.collapsed(offset: r.name.length);
    _hasTextVN.value = r.name.isNotEmpty;
    final next = LatLng(r.lat, r.lng);
    _userMovedMap = true;
    _mapController.move(next, 16);
    _centerVN.value = next;
    _labelVN.value = r.name;
    _addressVN.value = r.displayName;
    _suggestionsVN.value = const [];
    _searchErrorVN.value = null;
    _scheduleReverseGeocode(next, immediate: true);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchCancel?.cancel('cleared');
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
      const Duration(milliseconds: 400),
      () => _reverseGeocode(latLng),
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final token = CancelToken();
    _reverseCancel = token;
    try {
      final r = await _nominatim.reverse(
        lat: latLng.latitude,
        lng: latLng.longitude,
        cancelToken: token,
        acceptLanguage: 'en',
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
    final center = _centerVN.value;
    final cleanLabel = (_labelVN.value ?? '').trim();
    final addr = _addressVN.value;
    final fallback = '${center.latitude.toStringAsFixed(5)}, '
        '${center.longitude.toStringAsFixed(5)}';
    Navigator.of(context).pop(
      LocationPickResult(
        name: cleanLabel.isNotEmpty ? cleanLabel : fallback,
        address: (addr ?? '').isEmpty ? null : addr,
        latitude: center.latitude,
        longitude: center.longitude,
      ),
    );
  }

  // -------------------- build --------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinColor =
        widget.isPickup ? AppColor.accentColor : AppColor.errorColor;
    final mediaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: !_initialised
          ? const _BootstrapShimmer()
          : Stack(
              children: [
                // 1. The map. Wrapped in RepaintBoundary so that overlay
                //    repaints (compass spin, suggestion list updates) do
                //    NOT trigger a re-rasterisation of the tiles below.
                RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centerVN.value,
                      initialZoom: 16,
                      minZoom: 3,
                      maxZoom: 19,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'app.rafiq.user',
                        maxZoom: 19,
                        // Keep more off-screen tiles cached so panning feels
                        // instant instead of stuttering as new tiles fetch.
                        keepBuffer: 4,
                        // Skip the per-tile cross-fade — pure repaint cost
                        // for no UX benefit while panning aggressively.
                        tileDisplay: const TileDisplay.instantaneous(),
                        tileProvider: NetworkTileProvider(),
                      ),
                    ],
                  ),
                ),

                // 2. Pulsing centre pin.
                Center(child: _PulsingPin(color: pinColor)),

                // 3. Attribution.
                const Positioned(
                  left: 6,
                  bottom: 6,
                  child: _OsmCartoAttribution(),
                ),

                // 4. Initial 1s shimmer overlay — gated by a notifier so
                //    toggling it off doesn't rebuild the page.
                ValueListenableBuilder<bool>(
                  valueListenable: _showShimmerVN,
                  builder: (_, show, __) => show
                      ? const Positioned.fill(
                          child: IgnorePointer(child: _BootstrapShimmer()),
                        )
                      : const SizedBox.shrink(),
                ),

                // 5. Floating search bar. The bar itself never rebuilds
                //    while the user types — only the trailing affordance
                //    and suggestions dropdown listen to specific
                //    notifiers and rebuild in isolation.
                Positioned(
                  top: mediaTop + AppTheme.spaceSM,
                  left: AppTheme.spaceMD,
                  right: AppTheme.spaceMD,
                  child: _SearchBar(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    isSearchingVN: _searchingVN,
                    errorVN: _searchErrorVN,
                    suggestionsVN: _suggestionsVN,
                    hasTextVN: _hasTextVN,
                    onClear: _clearSearch,
                    onPick: _onPickSuggestion,
                    onBack: () => Navigator.of(context).maybePop(),
                    title: widget.title,
                    isPickup: widget.isPickup,
                  ),
                ),

                // 6. Compass badge — listens to bearing only.
                Positioned(
                  top: mediaTop + 80,
                  right: AppTheme.spaceMD,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _bearingVN,
                    builder: (_, bearing, __) => _CompassBadge(
                      rotationRad: bearing,
                      onTap: _onResetBearing,
                    ),
                  ),
                ),

                // 7. My-location FAB — listens to its own loading flag.
                Positioned(
                  right: AppTheme.spaceMD,
                  bottom: 220,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _myLocLoadingVN,
                    builder: (_, loading, __) => _MyLocationFab(
                      isLoading: loading,
                      onTap: _onUseMyLocation,
                    ),
                  ),
                ),

                // 8. Sticky bottom sheet — listens to label / address /
                //    resolving / centre notifiers.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _LiveBottomSheet(
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

// ============================================================================
// Search bar + dropdown
// ============================================================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueListenable<bool> isSearchingVN;
  final ValueListenable<String?> errorVN;
  final ValueListenable<List<NominatimResult>> suggestionsVN;
  final ValueListenable<bool> hasTextVN;
  final VoidCallback onClear;
  final ValueChanged<NominatimResult> onPick;
  final VoidCallback onBack;
  final String title;
  final bool isPickup;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearchingVN,
    required this.errorVN,
    required this.suggestionsVN,
    required this.hasTextVN,
    required this.onClear,
    required this.onPick,
    required this.onBack,
    required this.title,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                  splashRadius: 22,
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Icon(
                  isPickup ? Icons.trip_origin_rounded : Icons.flag_rounded,
                  size: 18,
                  color: isPickup
                      ? AppColor.accentColor
                      : AppColor.errorColor,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => focusNode.unfocus(),
                    // Tap outside the field (e.g. on the map) closes the
                    // keyboard so the user is never trapped behind it.
                    onTapOutside: (_) => focusNode.unfocus(),
                    decoration: InputDecoration(
                      hintText: isPickup
                          ? 'Search pickup, e.g. Tahrir Square'
                          : 'Search destination, e.g. Pyramids',
                      hintStyle: const TextStyle(
                        color: AppColor.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          _SuggestionsPanel(
            suggestionsVN: suggestionsVN,
            errorVN: errorVN,
            controller: controller,
            onPick: onPick,
          ),
        ],
      ),
    );
  }
}

/// Trailing affordance of the search bar. The X (clear) button is ALWAYS
/// shown when there is any text — even while a request is in flight — so
/// the user has an unmistakable escape hatch if Nominatim is slow. The
/// spinner is rendered inline next to the X, never *instead* of it.
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
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (hasText)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear',
                onPressed: onClear,
                splashRadius: 22,
              )
            else if (!searching)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.search_rounded,
                    color: AppColor.lightTextSecondary),
              ),
          ],
        );
      },
    );
  }
}

/// Suggestions dropdown / "no results" pill below the search bar. Wired
/// through ValueListenables so updating the search results does NOT
/// rebuild the search bar tree (and therefore does not steal frames from
/// the keyboard / TextField).
class _SuggestionsPanel extends StatelessWidget {
  final ValueListenable<List<NominatimResult>> suggestionsVN;
  final ValueListenable<String?> errorVN;
  final TextEditingController controller;
  final ValueChanged<NominatimResult> onPick;

  const _SuggestionsPanel({
    required this.suggestionsVN,
    required this.errorVN,
    required this.controller,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<List<NominatimResult>>(
      valueListenable: suggestionsVN,
      builder: (_, list, __) {
        if (list.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  indent: 52,
                ),
                itemBuilder: (context, i) {
                  final s = list[i];
                  return _SuggestionTile(
                    result: s,
                    onTap: () => onPick(s),
                  );
                },
              ),
            ),
          );
        }
        return ValueListenableBuilder<String?>(
          valueListenable: errorVN,
          builder: (_, err, __) {
            if (err == null || controller.text.length < 2) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColor.lightTextSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        err,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final NominatimResult result;
  final VoidCallback onTap;
  const _SuggestionTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.secondaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.place_rounded,
                color: AppColor.secondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.displayName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        result.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.north_west_rounded,
              size: 18,
              color: AppColor.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Compass badge + my-location FAB
// ============================================================================

class _CompassBadge extends StatelessWidget {
  final double rotationRad;
  final VoidCallback onTap;
  const _CompassBadge({required this.rotationRad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Transform.rotate(
            angle: rotationRad * (3.1415926535 / 180.0) * -1,
            child: const Icon(
              Icons.explore_rounded,
              color: AppColor.secondaryColor,
              size: 22,
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
    return Material(
      color: AppColor.secondaryColor,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: AppColor.secondaryColor.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          width: 52,
          height: 52,
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
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Center pin (pulsing teardrop)
// ============================================================================

class _PulsingPin extends StatefulWidget {
  final Color color;
  const _PulsingPin({required this.color});

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
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
        width: 80,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring (animates 1.0 -> 1.4 scale, 0.4 -> 0 opacity).
            Positioned(
              bottom: 14,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final v = _ctrl.value;
                  return Opacity(
                    opacity: (1 - v) * 0.4,
                    child: Transform.scale(
                      scale: 1 + v * 0.4,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Solid base dot (so the user knows the exact point).
            Positioned(
              bottom: 18,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            // Teardrop shape with inner dot.
            Positioned(
              top: 6,
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
      width: 36,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Drop shadow.
          Positioned(
            top: 4,
            child: CustomPaint(
              size: const Size(34, 46),
              painter: _DropPainter(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          // Filled teardrop.
          CustomPaint(
            size: const Size(34, 46),
            painter: _DropPainter(color: color),
          ),
          // White inner dot.
          const Positioned(
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 10, height: 10),
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
    path.cubicTo(
      w * 0.05, h * 0.62,
      w * 0.0, h * 0.20,
      w * 0.5, 0,
    );
    path.cubicTo(
      w * 1.0, h * 0.20,
      w * 0.95, h * 0.62,
      w / 2, h,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Bottom sheet (sticky address + Confirm)
// ============================================================================

/// Bottom sheet that listens to the picker's ValueNotifiers, so only the
/// dynamic bits (linear progress, label, address, lat/lng) rebuild as the
/// user pans the map — the surrounding map and search list stay still.
class _LiveBottomSheet extends StatelessWidget {
  final bool isPickup;
  final ValueListenable<String?> labelVN;
  final ValueListenable<String?> addressVN;
  final ValueListenable<bool> resolvingVN;
  final ValueListenable<LatLng> centerVN;
  final VoidCallback onConfirm;

  const _LiveBottomSheet({
    required this.isPickup,
    required this.labelVN,
    required this.addressVN,
    required this.resolvingVN,
    required this.centerVN,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -8),
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
                  ? const LinearProgressIndicator(minHeight: 3)
                  : const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMD,
              AppTheme.spaceMD,
              AppTheme.spaceMD,
              AppTheme.spaceMD,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isPickup
                                ? AppColor.accentColor
                                : AppColor.errorColor)
                            .withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPickup
                            ? Icons.trip_origin_rounded
                            : Icons.flag_rounded,
                        color: isPickup
                            ? AppColor.accentColor
                            : AppColor.errorColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
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
                const SizedBox(height: AppTheme.spaceMD),
                _ConfirmButton(
                  label: isPickup ? 'Confirm pickup' : 'Confirm destination',
                  enabled: true,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isPickup ? 'PICKUP POINT' : 'DESTINATION',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColor.lightTextSecondary,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        ValueListenableBuilder<String?>(
          valueListenable: labelVN,
          builder: (_, label, __) => Text(
            (label == null || label.trim().isEmpty)
                ? 'Move the map to choose a point'
                : label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColor.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<LatLng>(
          valueListenable: centerVN,
          builder: (_, center, __) => Text(
            '${center.latitude.toStringAsFixed(5)}, '
            '${center.longitude.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColor.lightTextSecondary,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ConfirmButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            gradient: const LinearGradient(
              colors: [AppColor.accentColor, AppColor.secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColor.secondaryColor.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            onTap: enabled ? onTap : null,
            child: Container(
              height: 56,
              alignment: Alignment.center,
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
                      fontWeight: FontWeight.w700,
                    ),
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

// ============================================================================
// Bootstrap shimmer + attribution
// ============================================================================

class _BootstrapShimmer extends StatelessWidget {
  const _BootstrapShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF1F4),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Finding your location...',
            style: TextStyle(
              color: AppColor.lightTextSecondary.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmCartoAttribution extends StatelessWidget {
  const _OsmCartoAttribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '\u00A9 OpenStreetMap contributors \u00A9 CARTO',
        style: TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
