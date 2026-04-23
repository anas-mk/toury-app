import 'package:flutter/material.dart';

class HistoryShortcutCard extends StatelessWidget {
  final VoidCallback onTap;

  const HistoryShortcutCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking History',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'View your past completed trips',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
