import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/currency_format.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../helper_bookings/domain/entities/helper_earnings_entities.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../data/static_wallet_data.dart';

/// Single canonical "money" page for the Helper.
///
/// Shows an earnings overview at a glance. Full invoice management lives in
/// [InvoicesPage] (`helper-invoices` route).
class WalletHubPage extends StatefulWidget {
  const WalletHubPage({super.key});

  @override
  State<WalletHubPage> createState() => _WalletHubPageState();
}

class _WalletHubPageState extends State<WalletHubPage> {
  late final EarningsCubit _earningsCubit;
  late final HelperInvoicesCubit _summaryCubit;

  @override
  void initState() {
    super.initState();
    _earningsCubit = sl<EarningsCubit>()..load();
    _summaryCubit = sl<HelperInvoicesCubit>()..loadSummary();
  }

  @override
  void dispose() {
    _earningsCubit.close();
    _summaryCubit.close();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _earningsCubit.load(),
      _summaryCubit.loadSummary(),
    ]);
  }

  void _openInvoices() {
    HapticService.light();
    context.pushNamed('helper-invoices');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _earningsCubit),
        BlocProvider.value(value: _summaryCubit),
      ],
      child: AppScaffold(
        backgroundColor: palette.scaffold,
        appBar: AppBar(
          backgroundColor: palette.scaffold,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Wallet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.receipt_long_rounded,
                color: palette.textSecondary,
                size: 20,
              ),
              tooltip: 'Your invoices',
              onPressed: _openInvoices,
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: palette.textSecondary,
                size: 20,
              ),
              tooltip: 'Refresh',
              onPressed: () {
                HapticService.light();
                _refreshAll();
              },
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: _WalletOverview(
          summaryCubit: _summaryCubit,
          onRefresh: _refreshAll,
          onOpenInvoices: _openInvoices,
        ),
      ),
    );
  }
}

// ─── Overview ────────────────────────────────────────────────────────────────
class _WalletOverview extends StatelessWidget {
  final HelperInvoicesCubit summaryCubit;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenInvoices;

  const _WalletOverview({
    required this.summaryCubit,
    required this.onRefresh,
    required this.onOpenInvoices,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      color: palette.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          AppSpacing.sm,
          AppSpacing.pageGutter,
          AppSpacing.huge,
        ),
        children: [
          BlocBuilder<EarningsCubit, EarningsState>(
            builder: (context, state) {
              if (state is EarningsLoaded) {
                return FadeInSlide(
                  delay: const Duration(milliseconds: 60),
                  child: _BalanceHero(earnings: state.earnings),
                );
              }
              if (state is EarningsError) {
                return AppErrorState(
                  message: state.message,
                  onRetry: () => context.read<EarningsCubit>().load(),
                );
              }
              return const _BalanceHeroShimmer();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<EarningsCubit, EarningsState>(
            buildWhen: (a, b) => b is EarningsLoaded || a is EarningsLoaded,
            builder: (context, state) {
              if (state is EarningsLoaded) {
                final earnings = state.earnings;
                return FadeInSlide(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'This Week',
                          value: Money.egp(earnings.week, decimals: false),
                          color: palette.primary,
                          icon: Icons.calendar_view_week_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MiniStat(
                          label: 'This Month',
                          value: Money.egp(earnings.month, decimals: false),
                          color: palette.success,
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox(height: 80);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeInSlide(
            delay: const Duration(milliseconds: 180),
            child: _SectionHeader(
              title: 'Your invoices',
              actionLabel: 'View all',
              onAction: onOpenInvoices,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
            bloc: summaryCubit,
            buildWhen: (a, b) =>
                b is InvoiceSummaryLoaded ||
                b is InvoiceSummaryLoading ||
                b is InvoicesError ||
                a is InvoiceSummaryLoaded,
            builder: (context, state) {
              if (state is InvoiceSummaryLoading || state is InvoicesInitial) {
                return const _InvoiceSummaryShimmer();
              }
              if (state is InvoiceSummaryLoaded) {
                final summary = StaticWalletData.invoiceSummaryForDisplay(
                  state.summary,
                );
                return FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: _InvoiceSummaryStrip(
                    invoiceCount: summary.invoiceCount,
                    netAmount: summary.netAmount,
                    onTap: onOpenInvoices,
                  ),
                );
              }
              if (state is InvoicesError) {
                return AppErrorState(
                  message: state.message,
                  onRetry: () => summaryCubit.loadSummary(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeInSlide(
            delay: const Duration(milliseconds: 220),
            child: const _SectionHeader(
              title: 'Recent Payouts',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<EarningsCubit, EarningsState>(
            builder: (context, state) {
              if (state is EarningsLoaded) {
                final payouts = state.earnings.recentEarnings;
                if (payouts.isEmpty) {
                  return FadeInSlide(
                    delay: const Duration(milliseconds: 240),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        'No payouts yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.of(context).textSecondary,
                            ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: payouts.asMap().entries.map((entry) {
                    return FadeInSlide(
                      delay: Duration(
                        milliseconds: 240 + (entry.key * 50).clamp(0, 240),
                      ),
                      child: _PayoutTile(item: entry.value),
                    );
                  }).toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Balance Hero ────────────────────────────────────────────────────────────
class _BalanceHero extends StatelessWidget {
  final HelperEarnings earnings;
  const _BalanceHero({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl + AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primary,
            palette.primaryStrong,
            palette.success.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -16,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -12,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Earnings",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                Money.egp(earnings.today),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 14,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${earnings.completedTrips} trips completed',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceHeroShimmer extends StatelessWidget {
  const _BalanceHeroShimmer();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
    );
  }
}

// ─── Mini Stat ───────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm + AppSpacing.xs),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Invoice Summary Strip ───────────────────────────────────────────────────
class _InvoiceSummaryStrip extends StatelessWidget {
  final int invoiceCount;
  final double netAmount;
  final VoidCallback onTap;

  const _InvoiceSummaryStrip({
    required this.invoiceCount,
    required this.netAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primary.withValues(alpha: 0.20),
                      palette.success.withValues(alpha: 0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: palette.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$invoiceCount invoices · Net ${Money.egp(netAmount, decimals: false)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: palette.textMuted,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceSummaryShimmer extends StatelessWidget {
  const _InvoiceSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Payout Tile ─────────────────────────────────────────────────────────────
class _PayoutTile extends StatelessWidget {
  final EarningItem item;
  const _PayoutTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.successSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_rounded,
              color: palette.success,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.travelerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(item.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+ ${Money.egp(item.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
