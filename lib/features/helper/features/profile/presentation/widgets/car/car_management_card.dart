import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/car_entity.dart';
import '../empty_states/empty_state_card.dart';

class CarManagementCard extends StatelessWidget {
  final CarEntity? car;

  const CarManagementCard({
    super.key,
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    if (car == null) {
      return EmptyStateCard(
        icon: Icons.directions_car,
        title: 'No Car Registered',
        description: 'Required if you intend to offer transportation services.',
        actionLabel: 'Add Car Details',
        onAction: () {
          // Open Add Car Form
        },
      );
    }

    final theme = Theme.of(context);
    final c = car!;

    return CustomCard(
      variant: CardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle Information',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                    onPressed: () {
                      // Open Edit Car Form
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      // Trigger delete car
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          _CarDetailRow(label: 'Brand & Model', value: '${c.brand} ${c.model}'),
          const SizedBox(height: AppTheme.spaceSM),
          _CarDetailRow(label: 'License Plate', value: c.licensePlate),
          const SizedBox(height: AppTheme.spaceSM),
          _CarDetailRow(label: 'Color', value: c.color),
          const SizedBox(height: AppTheme.spaceSM),
          _CarDetailRow(label: 'Energy & Type', value: '${c.energyType}  ${c.carType}'),
        ],
      ),
    );
  }
}

class _CarDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _CarDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
