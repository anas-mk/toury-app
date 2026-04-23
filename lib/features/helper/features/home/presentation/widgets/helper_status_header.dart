import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_theme.dart';

class HelperStatusHeader extends StatelessWidget {
  final String name;
  final bool isBusy;

  const HelperStatusHeader({
    super.key,
    required this.name,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        InkWell(
          onTap: () => context.push(AppRouter.helperLocation),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBusy ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isBusy ? Colors.orange : Colors.green),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: isBusy ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  isBusy ? 'Busy' : 'Available',
                  style: TextStyle(
                    color: isBusy ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
