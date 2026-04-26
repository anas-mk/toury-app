import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../domain/entities/search_params.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../cubits/search_helpers_cubit.dart';
import '../cubits/search_helpers_state.dart';
import '../widgets/helper_search_card.dart';

class InstantSearchPage extends StatefulWidget {
  final HelperBookingEntity? preSelectedHelper;

  const InstantSearchPage({super.key, this.preSelectedHelper});

  @override
  State<InstantSearchPage> createState() => _InstantSearchPageState();
}

class _InstantSearchPageState extends State<InstantSearchPage> {
  final TextEditingController _pickupController = TextEditingController();
  int _durationMinutes = 120;
  bool _requiresCar = false;

  @override
  void initState() {
    super.initState();
    _pickupController.text = 'My Location';
    // Auto-trigger search on page open — cubit will resolve GPS
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSearch());
  }

  @override
  void dispose() {
    _pickupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('instant_search'))),
      body: Column(
        children: [
          _buildSearchPanel(context, theme),
          Expanded(
            child: BlocBuilder<SearchHelpersCubit, SearchHelpersState>(
              builder: (context, state) => _buildBody(context, theme, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, SearchHelpersState state) {
    if (state is SearchHelpersLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding available helpers…', style: TextStyle(color: AppColor.lightTextSecondary)),
          ],
        ),
      );
    }

    if (state is SearchHelpersError) {
      if (state.isLocating) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location…', style: TextStyle(color: AppColor.lightTextSecondary)),
            ],
          ),
        );
      }
      return _buildErrorState(context, state);
    }

    if (state is SearchHelpersLoaded) {
      if (state.helpers.isEmpty) return _buildEmptyState(context, theme);
      return _buildHelperList(state.helpers);
    }

    // Initial / idle state
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.my_location_rounded, size: 64, color: AppColor.lightBorder),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Searching for helpers near you…',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperList(List<HelperBookingEntity> helpers) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      itemCount: helpers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
      itemBuilder: (context, index) {
        final helper = helpers[index];
        return HelperSearchCard(
          helper: helper,
          onTap: () => context.pushNamed(
            'helper-profile',
            pathParameters: {'id': helper.id},
            extra: {
              'helper': helper,
              'searchParams': _buildParams(
                // Use actual resolved coordinates from helper if available
                lat: helper.latitude ?? 0.0,
                lng: helper.longitude ?? 0.0,
              ),
              'isInstant': true,
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded, size: 64, color: AppColor.lightBorder),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'No helpers available right now',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            const Text(
              'Try a different pickup location or change the duration. New helpers come online frequently!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.lightTextSecondary),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            ElevatedButton.icon(
              onPressed: _onSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Search Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SearchHelpersError state) {
    final isPermanentDenial = state.isPermissionPermanentlyDenied;
    final isGpsOff = state.isServiceDisabled;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermanentDenial
                  ? Icons.lock_outline_rounded
                  : isGpsOff
                      ? Icons.location_off_rounded
                      : Icons.wifi_off_rounded,
              size: 60,
              color: AppColor.warningColor,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            if (isPermanentDenial) ...[
              ElevatedButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open App Settings'),
              ),
            ] else if (isGpsOff) ...[
              ElevatedButton.icon(
                onPressed: () => Geolocator.openLocationSettings(),
                icon: const Icon(Icons.gps_fixed_rounded),
                label: const Text('Enable GPS'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextButton(
                onPressed: _onSearch,
                child: const Text('Try Again'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _onSearch,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: AppTheme.shadowLight(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup location field
          TextField(
            controller: _pickupController,
            decoration: InputDecoration(
              hintText: 'Pickup location or city',
              prefixIcon: const Icon(Icons.near_me_rounded, color: AppColor.primaryColor),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: _onSearch,
              ),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          // Duration + car option row
          Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded, size: 16, color: AppColor.lightTextSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButton<int>(
                  value: _durationMinutes,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: theme.textTheme.bodyMedium,
                  items: const [
                    DropdownMenuItem(value: 60, child: Text('1 Hour')),
                    DropdownMenuItem(value: 120, child: Text('2 Hours')),
                    DropdownMenuItem(value: 180, child: Text('3 Hours')),
                    DropdownMenuItem(value: 240, child: Text('4 Hours')),
                    DropdownMenuItem(value: 360, child: Text('6 Hours')),
                    DropdownMenuItem(value: 480, child: Text('8 Hours')),
                  ],
                  onChanged: (v) => setState(() => _durationMinutes = v ?? 120),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              FilterChip(
                label: const Text('Car'),
                selected: _requiresCar,
                avatar: const Icon(Icons.directions_car_rounded, size: 16),
                onSelected: (v) => setState(() => _requiresCar = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build params with 0.0 coordinates — the cubit will resolve GPS automatically.
  InstantSearchParams _buildParams({double lat = 0.0, double lng = 0.0}) {
    return InstantSearchParams(
      pickupLocationName: _pickupController.text.trim().isEmpty
          ? 'My Location'
          : _pickupController.text.trim(),
      pickupLatitude: lat,
      pickupLongitude: lng,
      durationInMinutes: _durationMinutes,
      requestedLanguage: 'en',
      requiresCar: _requiresCar,
      travelersCount: 1,
    );
  }

  void _onSearch() {
    // Pass 0.0 — cubit handles GPS resolution automatically
    context.read<SearchHelpersCubit>().scheduleInstantSearch(_buildParams());
  }
}
