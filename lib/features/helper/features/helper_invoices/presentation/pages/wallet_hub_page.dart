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
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../helper_bookings/domain/entities/helper_earnings_entities.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../widgets/invoice_list_item.dart';

/// Single canonical "money" page for the Helper.
///
/// Tabs:
///  • Overview  — earnings hero + invoice summary at a glance.
///  • Invoices  — full paginated invoice list (powered by the same widgets
///    used in `InvoicesPage` so we keep one source of truth for cards).
class WalletHubPage extends StatefulWidget {
  const WalletHubPage({super.key});

  @override
  State<WalletHubPage> createState() => _WalletHubPageState();
}

class _WalletHubPageState extends State<WalletHubPage>
    with SingleTickerProviderStateMixin {
  late final EarningsCubit _earningsCubit;
  late final HelperInvoicesCubit _invoicesCubit;
  late final HelperInvoicesCubit _summaryCubit;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _earningsCubit = sl<EarningsCubit>()..load();
    _invoicesCubit = sl<HelperInvoicesCubit>()..loadInvoices();
    _summaryCubit = sl<HelperInvoicesCubit>()..loadSummary();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _earningsCubit.close();
    _invoicesCubit.close();
    _summaryCubit.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _earningsCubit.load(),
      _invoicesCubit.refresh(),
      _summaryCubit.loadSummary(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _earningsCubit),
        BlocProvider.value(value: _invoicesCubit),
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
                Icons.history_rounded,
                color: palette.textSecondary,
                size: 20,
              ),
              tooltip: 'All invoices',
              onPressed: () => context.pushNamed('helper-invoices'),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _SegmentedTabs(controller: _tabController),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(onRefresh: _refreshAll),
            _InvoicesTab(cubit: _invoicesCubit),
          ],
        ),
      ),
    );
  }
}

// ─── Segmented Tabs ──────────────────────────────────────────────────────────
class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  const _SegmentedTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.primaryStrong],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Invoices'),
        ],
      ),
    );
  }
}

// ─── Overview Tab ────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _OverviewTab({required this.onRefresh});

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
                return FadeInSlide(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'This Week',
                          value: Money.egp(state.earnings.week, decimals: false),
                          color: palette.primary,
                          icon: Icons.calendar_view_week_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MiniStat(
                          label: 'This Month',
                          value: Money.egp(state.earnings.month, decimals: false),
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
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
            bloc: BlocProvider.of<HelperInvoicesCubit>(context),
            buildWhen: (a, b) =>
                b is InvoiceSummaryLoaded || a is InvoiceSummaryLoaded,
            builder: (context, state) {
              if (state is InvoiceSummaryLoaded) {
                return FadeInSlide(
                  delay: const Duration(milliseconds: 180),
                  child: _InvoiceSummaryStrip(summary: state),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeInSlide(
            delay: const Duration(milliseconds: 220),
            child: _SectionHeader(
              title: 'Recent Payouts',
              actionLabel: null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<EarningsCubit, EarningsState>(
            builder: (context, state) {
              if (state is EarningsLoaded) {
                final list = state.earnings.recentEarnings;
                if (list.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No payouts yet',
                    message:
                        'Your earnings will appear here once you complete trips.',
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                  );
                }
                return Column(
                  children: list.asMap().entries.map((entry) {
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
  final InvoiceSummaryLoaded summary;
  const _InvoiceSummaryStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final s = summary.summary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.pushNamed('helper-invoices'),
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
                      '${s.invoiceCount} invoices · Net ${Money.egp(s.netAmount, decimals: false)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to see all your invoices',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
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

// ─── Section Header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  const _SectionHeader({required this.title, this.actionLabel});

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
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
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

// ─── Invoices Tab ────────────────────────────────────────────────────────────
class _InvoicesTab extends StatelessWidget {
  final HelperInvoicesCubit cubit;
  const _InvoicesTab({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
      bloc: cubit,
      buildWhen: (a, b) =>
          b is InvoicesLoaded ||
          b is InvoicesLoading ||
          b is InvoicesEmpty ||
          b is InvoicesError,
      builder: (context, state) {
        if (state is InvoicesLoading || state is InvoicesInitial) {
          return const Center(child: AppLoading(fullScreen: false));
        }
        if (state is InvoicesError) {
          return AppErrorState(
            message: state.message,
            onRetry: () => cubit.refresh(),
          );
        }
        if (state is InvoicesEmpty ||
            (state is InvoicesLoaded && state.invoices.isEmpty)) {
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.refresh(),
            color: palette.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                AppEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No invoices yet',
                  message:
                      'Completed bookings with billing details will appear here.',
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                ),
              ],
            ),
          );
        }
        if (state is InvoicesLoaded) {
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.refresh(),
            color: palette.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.md,
                0,
                AppSpacing.huge,
              ),
              itemCount: state.invoices.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: (index * 40).clamp(0, 240)),
                child: InvoiceListItem(invoice: state.invoices[index]),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
