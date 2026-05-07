import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/helper_booking_entity.dart';

class HelperSearchCard extends StatelessWidget {
  final HelperBookingEntity helper;
  final VoidCallback onTap;

  const HelperSearchCard({
    super.key,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppColor.lightBorder),
          boxShadow: AppTheme.shadowLight(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: AppNetworkImage(
                imageUrl: helper.profileImageUrl ?? '',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        helper.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            helper.rating.toString(),
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${helper.completedTrips} trips completed',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Wrap(
                    spacing: 4,
                    children: helper.languages.take(3).map((lang) => _buildLanguageChip(lang)).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Column(
              children: [
                Text(
                  '${helper.hourlyRate ?? 0}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColor.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'USD/hr',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.lightBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        lang,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
