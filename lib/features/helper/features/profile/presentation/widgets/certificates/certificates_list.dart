import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Open Add Certificate Flow
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
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
                  child: Icon(Icons.verified, color: theme.colorScheme.primary),
                ),
                title: Text(
                  cert.name,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: cert.issuingOrganization != null 
                    ? Text(cert.issuingOrganization!) 
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
