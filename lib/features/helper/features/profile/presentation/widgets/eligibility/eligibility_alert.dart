import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';

import '../../../domain/entities/helper_eligibility_entity.dart';

class EligibilityAlert extends StatelessWidget {
  final HelperEligibilityEntity eligibility;

  const EligibilityAlert({
    super.key,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    if (eligibility.isEligible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return CustomCard(
      variant: CardVariant.elevated,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Action Required',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (eligibility.blockingReasons.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            ...eligibility.blockingReasons.map((reason) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right_rounded,
                      color: Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reason,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
