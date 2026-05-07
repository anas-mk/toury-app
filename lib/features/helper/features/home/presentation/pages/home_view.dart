import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 70,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColor.lightBorder,
                      child: Icon(Icons.person, color: AppColor.primaryColor),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Helper Professional',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
                const SizedBox(width: AppTheme.spaceMD),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.spaceMD),

                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColor.primaryColor, Color(0xFF333333)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: AppTheme.shadowMedium(context),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Professional Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppTheme.spaceSM),
                        Text(
                          'Manage your profile and certificates here.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: AppTheme.spaceLG),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceXL * 2),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
