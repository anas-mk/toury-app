import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/service_area_entity.dart';

class ServiceAreaCard extends StatelessWidget {
  final ServiceAreaEntity area;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServiceAreaCard({
    super.key,
    required this.area,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.city,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (area.areaName != null && area.areaName!.isNotEmpty)
                      Text(
                        area.areaName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              if (area.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSM,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                area.country,
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Icon(Icons.radar_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                '${area.radiusKm.toInt()} km',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const Divider(height: AppTheme.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: AppColor.primaryColor,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: AppColor.errorColor,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
