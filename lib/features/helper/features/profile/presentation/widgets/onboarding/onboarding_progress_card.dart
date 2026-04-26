import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/helper_profile_entity.dart';

class OnboardingProgressCard extends StatelessWidget {
  final HelperProfileEntity profile;
  
  const OnboardingProgressCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Evaluate steps
    final bool hasImage = profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty;
    final bool hasSelfie = profile.selfieImageUrl != null && profile.selfieImageUrl!.isNotEmpty;
    final bool hasCar = profile.car != null;
    final bool hasDocuments = profile.certificates.isNotEmpty; // For simplicity, check certs
    
    int totalSteps = 4;
    int completedSteps = 0;
    List<String> missingSteps = [];
    
    if (hasImage) completedSteps++; else missingSteps.add("Profile Image");
    if (hasSelfie) completedSteps++; else missingSteps.add("Selfie Verification");
    if (hasCar) completedSteps++; else missingSteps.add("Car Details (Required for Drivers)");
    if (hasDocuments) completedSteps++; else missingSteps.add("Certificates & Documents");

    double progress = completedSteps / totalSteps;
    bool isComplete = progress == 1.0;

    return CustomCard(
      variant: CardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Onboarding Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isComplete ? Colors.green : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ),
          
          if (!isComplete && missingSteps.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Pending Requirements:',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            ...missingSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_unchecked, size: 16, color: Colors.orange),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
