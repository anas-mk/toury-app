import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/price_breakdown.dart';

class PriceBreakdownCard extends StatelessWidget {
  final PriceBreakdown breakdown;
  const PriceBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = breakdown.currency ?? 'EGP';

    final lines = <_Line>[
      if (breakdown.baseFare != null)
        _Line('Base fare', breakdown.baseFare!),
      if (breakdown.hourlyTotal != null)
        _Line('Hourly charge', breakdown.hourlyTotal!),
      if (breakdown.carSurcharge != null && breakdown.carSurcharge! > 0)
        _Line('Car surcharge', breakdown.carSurcharge!),
      if (breakdown.distanceFee != null && breakdown.distanceFee! > 0)
        _Line('Distance fee', breakdown.distanceFee!),
      if (breakdown.travelerSurcharge != null &&
          breakdown.travelerSurcharge! > 0)
        _Line('Traveler surcharge', breakdown.travelerSurcharge!),
      if (breakdown.languageSurcharge != null &&
          breakdown.languageSurcharge! > 0)
        _Line('Language surcharge', breakdown.languageSurcharge!),
      if (breakdown.discount != null && breakdown.discount! > 0)
        _Line('Discount', -breakdown.discount!, isDiscount: true),
      if (breakdown.tax != null && breakdown.tax! > 0)
        _Line('Tax', breakdown.tax!),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColor.lightTextSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${l.isDiscount ? '−' : ''}$currency ${l.amount.abs().toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: l.isDiscount ? AppColor.accentColor : null,
                    ),
                  ),
                ],
              ),
            ),
          if (lines.isNotEmpty) const Divider(),
          Row(
            children: [
              Expanded(
                child: Text('Total', style: theme.textTheme.titleMedium),
              ),
              Text(
                '$currency ${breakdown.total.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line {
  final String label;
  final double amount;
  final bool isDiscount;
  const _Line(this.label, this.amount, {this.isDiscount = false});
}
