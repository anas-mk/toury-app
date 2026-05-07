import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/animations/fade_in_slide.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../../../helper_bookings/domain/entities/helper_earnings_entities.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../../domain/entities/invoice_entities.dart';
import '../../../helper_bookings/presentation/widgets/shared/empty_state_view.dart';

class WalletHubPage extends StatefulWidget {
  const WalletHubPage({super.key});

  @override
  State<WalletHubPage> createState() => _WalletHubPageState();
}

class _WalletHubPageState extends State<WalletHubPage> with SingleTickerProviderStateMixin {
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
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _earningsCubit),
        BlocProvider.value(value: _invoicesCubit),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Wallet Hub'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColor.primaryColor,
            labelColor: AppColor.primaryColor,
            unselectedLabelColor: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
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
    final theme = Theme.of(context);

    return BlocBuilder<EarningsCubit, EarningsState>(
      builder: (context, state) {
        if (state is EarningsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColor.primaryColor));
        }
        if (state is EarningsLoaded) {
          return RefreshIndicator(
            onRefresh: () async => cubit.load(),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              children: [
                FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  child: _BalanceHero(earnings: state.earnings),
                ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Text('Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Expanded(child: _MiniStatCard(label: 'Weekly', amount: state.earnings.week, color: AppColor.primaryColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _MiniStatCard(label: 'Monthly', amount: state.earnings.month, color: AppColor.accentColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: Text('Recent Payouts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                if (state.earnings.recentEarnings.isEmpty)
                  const FadeInSlide(
                    delay: Duration(milliseconds: 250),
                    child: EmptyStateView(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'No payouts yet',
                      subtitle: 'Your earnings will appear here after completing trips.',
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
        if (state is InvoicesLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColor.primaryColor));
        }
        if (state is InvoicesLoaded) {
          if (state.invoices.isEmpty) {
            return const EmptyStateView(
              icon: Icons.receipt_long_rounded,
              title: 'No invoices found',
              subtitle: 'Completed bookings with billing details will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => cubit.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColor.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${earnings.today.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text('${earnings.completedTrips} trips completed', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  const _MiniStatCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('\$${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColor.accentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: AppColor.accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.travelerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM d, yyyy').format(item.date), style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text('+\$${item.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColor.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
    final isDark = theme.brightness == Brightness.dark;
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';
    
    return GestureDetector(
      onTap: () => context.push('/helper/invoice-detail/${invoice.invoiceId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.lightBorder),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${invoice.invoiceNumber}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(invoice.userName, style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${invoice.currency} ${invoice.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColor.accentColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    invoice.paymentStatus.toUpperCase(),
                    style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white12 : Colors.black12, size: 12),
          ],
        ),
      ),
    );
  }
}
