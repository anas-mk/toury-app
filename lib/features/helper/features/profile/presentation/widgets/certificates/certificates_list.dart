import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/certificate_entity.dart';
import '../empty_states/empty_state_card.dart';

class CertificatesList extends StatelessWidget {
  final List<CertificateEntity> certificates;

  const CertificatesList({
    super.key,
    required this.certificates,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (certificates.isEmpty) {
      return EmptyStateCard(
        icon: Icons.workspace_premium,
        title: 'No Certificates',
        description: 'Add your language or professional certificates to stand out.',
        actionLabel: 'Add Certificate',
        onAction: () {
          // Open Add Certificate Bottom Sheet / Screen
        },
      );
    }

    return CustomCard(
      variant: CardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Certificates',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Open Add Certificate Flow
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: certificates.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cert = certificates[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified, color: theme.colorScheme.primary, size: 20),
                ),
                title: Text(
                  cert.name,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: cert.issuingOrganization != null 
                    ? Text(
                        cert.issuingOrganization!,
                        style: TextStyle(
                          color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                        ),
                      ) 
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColor.errorColor),
                  onPressed: () {
                    // Trigger delete confirmation logic
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
