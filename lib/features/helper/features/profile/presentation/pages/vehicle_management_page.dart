import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../domain/entities/car_entity.dart';
import '../widgets/car/car_management_card.dart';

class VehicleManagementPage extends StatelessWidget {
  final CarEntity? car;
  const VehicleManagementPage({super.key, this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vehicle Management'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        children: [
          Text(
            'Vehicle Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CarManagementCard(car: car),
          const SizedBox(height: 24),
          if (car != null) ...[
            _DetailRow(label: 'Brand', value: car!.brand),
            _DetailRow(label: 'Model', value: car!.model),
            _DetailRow(label: 'Color', value: car!.color),
            _DetailRow(label: 'Plate Number', value: car!.licensePlate),
            _DetailRow(label: 'Car Type', value: car?.carType ?? 'Standard'),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
