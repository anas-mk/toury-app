import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../../../helper_bookings/domain/entities/helper_earnings_entities.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../../domain/entities/invoice_entities.dart';

class WalletHubPage extends StatefulWidget {
  const WalletHubPage({super.key});

  @override
  State<WalletHubPage> createState() => _WalletHubPageState();
}

class _WalletHubPageState extends State<WalletHubPage>
    with SingleTickerProviderStateMixin {
  late final EarningsCubit _earningsCubit;
  late final HelperInvoicesCubit _invoicesCubit;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _earningsCubit = sl<EarningsCubit>()..load();
    _invoicesCubit = sl<HelperInvoicesCubit>()..loadInvoices();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _earningsCubit.close();
    _invoicesCubit.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _earningsCubit),
        BlocProvider.value(value: _invoicesCubit),
      ],
      child: AppScaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Wallet Hub',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: palette.primary,
            labelColor: palette.primary,
            unselectedLabelColor: palette.textSecondary,
            tabs: const [
              Tab(text: 'Earnings'),
              Tab(text: 'Invoices'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _EarningsView(cubit: _earningsCubit),
            _InvoicesView(cubit: _invoicesCubit),
          ],
        ),
      ),
    );
  }
}

class _EarningsView extends StatelessWidget {
  final EarningsCubit cubit;
  const _EarningsView({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EarningsCubit, EarningsState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final palette = AppColors.of(context);

        if (state is EarningsLoading) {
          return const Center(child: AppLoading(fullScreen: false));
        }
        if (state is EarningsError) {
          return AppErrorState(
            message: state.message,
            onRetry: () => cubit.load(),
          );
        }
        if (state is EarningsLoaded) {
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.load(),
            color: theme.colorScheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  child: _BalanceHero(earnings: state.earnings),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Weekly',
                          amount: state.earnings.week,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Monthly',
                          amount: state.earnings.month,
                          color: palette.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Recent Payouts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.earnings.recentEarnings.isEmpty)
                  FadeInSlide(
                    delay: const Duration(milliseconds: 250),
                    child: AppEmptyState(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'No payouts yet',
                      message:
                          'Your earnings will appear here after completing trips.',
                      padding: EdgeInsets.zero,
                    ),
                  )
                else
                  ...state.earnings.recentEarnings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return FadeInSlide(
                      delay: Duration(milliseconds: 250 + (index * 50)),
                      child: _TransactionTile(item: item),
                    );
                  }),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _InvoicesView extends StatelessWidget {
  final HelperInvoicesCubit cubit;
  const _InvoicesView({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
      builder: (context, state) {
        final theme = Theme.of(context);

        if (state is InvoicesLoading) {
          return const Center(child: AppLoading(fullScreen: false));
        }
        if (state is InvoicesError) {
          return AppErrorState(
            message: state.message,
            onRetry: () => cubit.refresh(),
          );
        }
        if (state is InvoicesLoaded) {
          if (state.invoices.isEmpty) {
            return RefreshIndicator.adaptive(
              onRefresh: () async => cubit.refresh(),
              color: theme.colorScheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                children: [
                  AppEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No invoices found',
                    message:
                        'Completed bookings with billing details will show up here.',
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async => cubit.refresh(),
            color: theme.colorScheme.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.invoices.length,
              itemBuilder: (context, index) => FadeInSlide(
                delay: Duration(milliseconds: index * 50),
                child: _InvoiceItem(invoice: state.invoices[index]),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final HelperEarnings earnings;
  const _BalanceHero({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primary,
            palette.primaryStrong.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.xxxl + AppSpacing.xs),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.28),
            blurRadius: AppSpacing.xxl,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Icon(
                Icons.account_balance_rounded,
                color: Colors.white.withValues(alpha: 0.82),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\$${earnings.today.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.pageGutter),
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white.withValues(alpha: 0.78),
                size: 14,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${earnings.completedTrips} trips completed',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.xxxl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final EarningItem item;
  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
            decoration: BoxDecoration(
              color: palette.successSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, color: palette.success, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.travelerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
            '+\$${item.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceItem extends StatelessWidget {
  final InvoiceEntity invoice;
  const _InvoiceItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';

    return GestureDetector(
      onTap: () => context.pushNamed(
        'helper-invoice-detail',
        pathParameters: {'id': invoice.invoiceId},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.xs),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${invoice.invoiceNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  invoice.userName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: (isPaid ? palette.success : palette.warning)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    invoice.paymentStatus.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPaid ? palette.success : palette.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: palette.textMuted,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
