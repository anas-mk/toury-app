import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/primary_action_card.dart';
import '../../../../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spaceXL),
          
          // --- Greeting Section ---
          Text(
            'Welcome back,',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          Text(
            'Helper Professional',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),

          // --- Primary Action Card ---
          PrimaryActionCard(
            title: 'Start your exam journey',
            description: 'Get certified and unlock new professional opportunities today.',
            buttonText: 'Browse Exams',
            onButtonPressed: () {
              // Navigation or Action
            },
          ),
          
          const SizedBox(height: AppTheme.spaceXL),

          // --- Statistics Section ---
          Text(
            'Performance Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: HomeStatCard(
                  icon: Icons.task_alt_rounded,
                  value: '3',
                  label: 'Active Tasks',
                  iconColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: HomeStatCard(
                  icon: Icons.account_balance_wallet_rounded,
                  value: '1,250',
                  label: 'Earnings (EGP)',
                  iconColor: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: HomeStatCard(
                  icon: Icons.star_rounded,
                  value: '4.7',
                  label: 'Rating',
                  iconColor: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceXL),

          // --- Quick Actions Grid ---
          Text(
            'Quick Actions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.spaceMD,
            crossAxisSpacing: AppTheme.spaceMD,
            childAspectRatio: 1.1,
            children: [
              QuickActionButton(
                icon: Icons.notifications_active_rounded,
                label: 'Requests',
                onTap: () => context.push(AppRouter.helperRequests),
                color: theme.colorScheme.primary,
              ),
              QuickActionButton(
                icon: Icons.calendar_month_rounded,
                label: 'Upcoming',
                onTap: () => context.push(AppRouter.helperUpcoming),
                color: Colors.purpleAccent,
              ),
              QuickActionButton(
                icon: Icons.directions_run_rounded,
                label: 'Active Trip',
                onTap: () => context.push(AppRouter.helperActive),
                color: Colors.orangeAccent,
              ),
              QuickActionButton(
                icon: Icons.history_rounded,
                label: 'History',
                onTap: () => context.push(AppRouter.helperHistory),
                color: Colors.blueGrey,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXL * 2),
        ],
      ),
    );
  }
}
