import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';

class UserInvoicesPage extends StatelessWidget {
  const UserInvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('wallet')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        itemCount: 5, // Mock data for now
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppColor.lightBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColor.accentColor,
                  child: Icon(Icons.receipt_rounded, color: Colors.white),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trip to Cairo', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('April 25, 2026', style: TextStyle(color: AppColor.lightTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '\$120.00',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColor.accentColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
