import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/usecases/get_helper_profile_usecase.dart';

class HelperProfilePage extends StatefulWidget {
  final String helperId;
  final HelperBookingEntity? initialHelper;
  final dynamic searchParams;
  final bool isInstant;

  const HelperProfilePage({
    super.key,
    required this.helperId,
    this.initialHelper,
    this.searchParams,
    this.isInstant = false,
  });

  @override
  State<HelperProfilePage> createState() => _HelperProfilePageState();
}

class _HelperProfilePageState extends State<HelperProfilePage> {
  HelperBookingEntity? _helper;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialHelper != null) {
      _helper = widget.initialHelper;
    } else {
      _fetchHelper();
    }
  }

  Future<void> _fetchHelper() async {
    setState(() { _isLoading = true; _error = null; });
    final usecase = sl<GetHelperProfileUseCase>();
    final result = await usecase(widget.helperId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _isLoading = false; _error = failure.message; }),
      (helper) => setState(() { _isLoading = false; _helper = helper; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _helper == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColor.errorColor),
              const SizedBox(height: AppTheme.spaceMD),
              Text(_error ?? 'Helper not found.'),
              const SizedBox(height: AppTheme.spaceMD),
              ElevatedButton.icon(
                onPressed: _fetchHelper,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final helper = _helper!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: helper.profileImageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Name + rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(helper.name, style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${helper.rating.toStringAsFixed(1)} (${helper.completedTrips} trips)',
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${helper.experienceYears} yrs experience • ${helper.gender}',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColor.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (helper.hourlyRate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${helper.hourlyRate!.toStringAsFixed(0)} EGP',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColor.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('per hour', style: theme.textTheme.labelSmall),
                        ],
                      ),
                  ],
                ),

                if (helper.estimatedPrice != null) ...[
                  const SizedBox(height: AppTheme.spaceSM),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColor.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Estimated: ${helper.estimatedPrice!.toStringAsFixed(2)} EGP for this trip',
                      style: TextStyle(color: AppColor.accentColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spaceXL),

                // Languages
                Text('Languages', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spaceSM),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: helper.languages.map((l) => Chip(label: Text(l))).toList(),
                ),

                // Suitability reasons (from search result)
                if (helper.suitabilityReasons != null && helper.suitabilityReasons!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceXL),
                  Text('Why this helper?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spaceSM),
                  ...helper.suitabilityReasons!.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColor.accentColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason, style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  )),
                ],

                const SizedBox(height: AppTheme.spaceXL),

                // About — uses real bio from API
                Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  helper.bio?.isNotEmpty == true
                      ? helper.bio!
                      : 'Professional local helper with extensive knowledge of ${helper.serviceAreas.isNotEmpty ? helper.serviceAreas.first.city : "the city"}.',
                  style: theme.textTheme.bodyMedium,
                ),

                // Service areas
                if (helper.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceXL),
                  Text('Service Areas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spaceSM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: helper.serviceAreas.map((a) => Chip(
                      label: Text(a.city + (a.areaName != null ? ' — ${a.areaName}' : '')),
                    )).toList(),
                  ),
                ],

                // Car info
                if (helper.car != null) ...[
                  const SizedBox(height: AppTheme.spaceXL),
                  Text('Vehicle', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spaceSM),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 18, color: AppColor.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${helper.car!.brand} ${helper.car!.model} • ${helper.car!.color}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],

                // Stats row
                const SizedBox(height: AppTheme.spaceXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(theme, Icons.thumb_up_rounded, '${(helper.acceptanceRate * 100).toInt()}%', 'Acceptance'),
                    _buildStat(theme, Icons.check_circle_rounded, '${helper.completedTrips}', 'Trips'),
                    _buildStat(theme, Icons.star_rounded, helper.rating.toStringAsFixed(1), 'Rating'),
                  ],
                ),

                const SizedBox(height: AppTheme.space2XL),

                CustomButton(
                  text: 'Select ${helper.name}',
                  onPressed: () => context.push(
                    '/booking-confirm',
                    extra: {
                      'helper': helper,
                      'searchParams': widget.searchParams,
                      'isInstant': widget.isInstant,
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(ThemeData theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColor.primaryColor, size: 22),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColor.lightTextSecondary)),
      ],
    );
  }
}
