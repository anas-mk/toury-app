import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../domain/entities/helper_booking_entity.dart';

class HelperProfilePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helper = initialHelper;

    if (helper == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(
                imageUrl: helper.profileImageUrl ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(helper.name, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${helper.rating} (${helper.completedTrips} trips)',
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${helper.hourlyRate ?? 0}',
                          style: theme.textTheme.headlineSmall?.copyWith(color: AppColor.accentColor),
                        ),
                        Text('USD/hr', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXL),
                
                Text('Languages', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTheme.spaceSM),
                Wrap(
                  spacing: 8,
                  children: helper.languages.map((l) => Chip(label: Text(l))).toList(),
                ),
                
                const SizedBox(height: AppTheme.spaceXL),
                Text('About', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  'Professional local helper with extensive knowledge of ${helper.serviceAreas.isNotEmpty ? helper.serviceAreas.first.areaName : "the city"}. I can help you with shopping, local transport, and finding the best hidden spots in the city.',
                  style: theme.textTheme.bodyMedium,
                ),
                
                const SizedBox(height: AppTheme.space2XL),
                
                CustomButton(
                  text: 'Select ${helper.name}',
                  onPressed: () => context.push(
                    AppRouter.bookingConfirm,
                    extra: {
                      'helper': helper,
                      'searchParams': searchParams,
                      'isInstant': isInstant,
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
}
