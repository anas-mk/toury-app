import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../../domain/entities/invoice_entities.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  late final HelperInvoicesCubit _cubit;
  late final HelperInvoicesCubit _summaryCubit;
  final ScrollController _scrollController = ScrollController();
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperInvoicesCubit>()..loadInvoices();
    _summaryCubit = sl<HelperInvoicesCubit>()..loadSummary();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    _summaryCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _summaryCubit),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: RefreshIndicator(
          color: AppColor.primaryColor,
          backgroundColor: theme.cardColor,
          onRefresh: () async {
            await _cubit.refresh();
            await _summaryCubit.loadSummary();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(context),
                ),
              ),

              // ── Summary Card ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
                  bloc: _summaryCubit,
                  builder: (context, state) {
                    if (state is InvoiceSummaryLoaded) return _SummaryCard(summary: state.summary);
                    return const _SummaryShimmer();
                  },
                ),
              ),

              // ── Filter Chips ─────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildFilterChips(context)),

              // ── Invoice List ─────────────────────────────────────────────────
              BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
                bloc: _cubit,
                builder: (context, state) {
                  if (state is InvoicesLoading) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const _InvoiceShimmerCard(),
                        childCount: 5,
                      ),
                    );
                  }

                  if (state is InvoicesEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState(context));
                  }

                  if (state is InvoicesError) {
                    return SliverFillRemaining(child: _buildErrorState(context, state.message));
                  }

                  if (state is InvoicesLoaded) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          if (i == state.invoices.length) {
                            return state.hasMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColor.primaryColor, strokeWidth: 2),
                                    ),
                                  )
                                : const SizedBox(height: 40);
                          }
                          return _InvoiceCard(invoice: state.invoices[i]);
                        },
                        childCount: state.invoices.length + 1,
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 56, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1A1F3C), const Color(0xFF0A0E1A)]
            : [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Invoices',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Your complete financial history',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filters = [null, 'paid', 'pending', 'cancelled'];
    final labels = {null: 'All', 'paid': 'Paid', 'pending': 'Pending', 'cancelled': 'Cancelled'};

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = _activeFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[f]!),
                selected: selected,
                onSelected: (_) {
                  setState(() => _activeFilter = f);
                  _cubit.loadInvoices(statusFilter: f);
                },
                backgroundColor: theme.cardColor,
                selectedColor: AppColor.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                    color: selected ? AppColor.primaryColor : (isDark ? Colors.white54 : Colors.black54), fontSize: 12),
                side: BorderSide(
                    color: selected
                        ? AppColor.primaryColor
                        : AppColor.lightBorder),
                checkmarkColor: AppColor.primaryColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Invoices',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...['All', 'Paid', 'Pending', 'Cancelled'].map((label) {
                final val = label == 'All' ? null : label.toLowerCase();
                return ListTile(
                  title: Text(label),
                  trailing: _activeFilter == val
                      ? const Icon(Icons.check_rounded, color: AppColor.primaryColor)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _activeFilter = val);
                    _cubit.loadInvoices(statusFilter: val);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColor.accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 72, color: AppColor.accentColor),
            ),
            const SizedBox(height: 24),
            Text('No invoices yet',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Completed trips will generate invoices here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppColor.errorColor),
            const SizedBox(height: 16),
            Text('Could not load invoices',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cubit.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Summary Card
// ──────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final InvoiceSummaryEntity summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColor.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Net Earnings', style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${summary.currency} ${fmt.format(summary.netAmount)}',
                      style: const TextStyle(
                          color: AppColor.accentColor, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${summary.invoiceCount} invoices',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColor.lightBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryItem(
                label: 'Gross',
                value: fmt.format(summary.grossAmount),
                currency: summary.currency,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 1),
              Container(width: 1, height: 40, color: AppColor.lightBorder),
              const SizedBox(width: 1),
              _SummaryItem(
                label: 'Commission',
                value: fmt.format(summary.commissionAmount),
                currency: summary.currency,
                color: AppColor.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String currency;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.currency, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text('$currency $value', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Invoice Card
// ──────────────────────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy');
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';

    return GestureDetector(
      onTap: () => context.push('/helper/invoice-detail/${invoice.invoiceId}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (isPaid ? AppColor.accentColor : Colors.orange).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_rounded,
                color: isPaid ? AppColor.accentColor : Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${invoice.invoiceNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(invoice.userName,
                      style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 12),
                      const SizedBox(width: 2),
                      Text(invoice.destinationCity,
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                      if (invoice.issuedAt != null) ...[
                        Text(' · ', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26)),
                        Text(dateFmt.format(invoice.issuedAt!),
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${invoice.currency} ${fmt.format(invoice.totalAmount)}',
                    style: const TextStyle(
                        color: AppColor.accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                _StatusBadge(status: invoice.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final color = s == 'paid'
        ? AppColor.accentColor
        : s == 'pending'
            ? Colors.orange
            : AppColor.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shimmer Cards
// ──────────────────────────────────────────────────────────────────────────────
class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 148,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _InvoiceShimmerCard extends StatelessWidget {
  const _InvoiceShimmerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
