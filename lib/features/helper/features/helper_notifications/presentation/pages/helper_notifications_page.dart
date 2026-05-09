import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../helper_bookings/presentation/cubit/incoming_requests_cubit.dart';

/// In-app notification hub for helpers: booking-related alerts today, with
/// room to grow when a notifications API exists.
class HelperNotificationsPage extends StatefulWidget {
  const HelperNotificationsPage({super.key});

  @override
  State<HelperNotificationsPage> createState() =>
      _HelperNotificationsPageState();
}

class _HelperNotificationsPageState extends State<HelperNotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<IncomingRequestsCubit>();
      if (cubit.state is IncomingRequestsInitial) {
        cubit.load(silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    Future<void> refresh() async {
      await context.read<IncomingRequestsCubit>().refresh();
    }

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        backgroundColor: palette.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: palette.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: palette.border.withValues(alpha: 0.45),
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        color: palette.primary,
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.lg,
            AppSpacing.pageGutter,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Bookings & trips',
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
              builder: (context, state) {
                var count = 0;
                var loading = state is IncomingRequestsLoading ||
                    state is IncomingRequestsInitial;
                if (state is IncomingRequestsLoaded) {
                  count = state.totalCount;
                  loading = false;
                }
                if (state is IncomingRequestsEmpty) {
                  count = 0;
                  loading = false;
                }

                return _HubTile(
                  icon: Icons.assignment_outlined,
                  iconColor: palette.primary,
                  title: 'Trip requests',
                  subtitle: loading
                      ? 'Loading…'
                      : count > 0
                          ? '$count pending — tap to review'
                          : 'No pending requests',
                  trailingBadge: (!loading && count > 0) ? count : null,
                  onTap: () {
                    HapticService.light();
                    context.push(AppRouter.helperRequests);
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Account & updates',
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: palette.border, width: 0.6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: palette.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Payouts, verification, and system messages will appear '
                      'here when available from RAFIQ.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int? trailingBadge;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Material(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: palette.border, width: 0.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: iconColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null && trailingBadge! > 0)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B5C),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    trailingBadge! > 99 ? '99+' : '${trailingBadge!}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
