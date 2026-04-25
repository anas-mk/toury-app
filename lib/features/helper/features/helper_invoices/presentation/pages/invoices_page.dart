import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _summaryCubit),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: RefreshIndicator(
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF1A1F3C),
          onRefresh: () async {
            await _cubit.refresh();
            await _summaryCubit.loadSummary();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: const Color(0xFF0A0E1A),
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
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
              SliverToBoxAdapter(child: _buildFilterChips()),

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
                    return SliverFillRemaining(child: _buildEmptyState());
                  }

                  if (state is InvoicesError) {
                    return SliverFillRemaining(child: _buildErrorState(state.message));
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
                                          color: Color(0xFF6C63FF), strokeWidth: 2),
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
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 56, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F3C), Color(0xFF0A0E1A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Invoices',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Your complete financial history',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
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
                backgroundColor: const Color(0xFF1A1F3C),
                selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                labelStyle: TextStyle(
                    color: selected ? const Color(0xFF6C63FF) : Colors.white54, fontSize: 12),
                side: BorderSide(
                    color: selected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.1)),
                checkmarkColor: const Color(0xFF6C63FF),
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
      backgroundColor: const Color(0xFF1A1F3C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Invoices',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['All', 'Paid', 'Pending', 'Cancelled'].map((label) {
              final val = label == 'All' ? null : label.toLowerCase();
              return ListTile(
                title: Text(label, style: const TextStyle(color: Colors.white)),
                trailing: _activeFilter == val
                    ? const Icon(Icons.check_rounded, color: Color(0xFF6C63FF))
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 72, color: Color(0xFF00C896)),
            ),
            const SizedBox(height: 24),
            const Text('No invoices yet',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Completed trips will generate invoices here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            const Text('Could not load invoices',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cubit.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F3C), Color(0xFF252B50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
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
                  const Text('Net Earnings', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${summary.currency} ${fmt.format(summary.netAmount)}',
                      style: const TextStyle(
                          color: Color(0xFF00C896), fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${summary.invoiceCount} invoices',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryItem(
                label: 'Gross',
                value: fmt.format(summary.grossAmount),
                currency: summary.currency,
                color: Colors.white70,
              ),
              const SizedBox(width: 1),
              Container(width: 1, height: 40, color: Colors.white12),
              const SizedBox(width: 1),
              _SummaryItem(
                label: 'Commission',
                value: fmt.format(summary.commissionAmount),
                currency: summary.currency,
                color: const Color(0xFFFF6B6B),
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
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy');
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';

    return GestureDetector(
      onTap: () => context.push('/helper-invoice-detail/${invoice.invoiceId}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (isPaid ? const Color(0xFF00C896) : Colors.orange).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_rounded,
                color: isPaid ? const Color(0xFF00C896) : Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${invoice.invoiceNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(invoice.userName,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white24, size: 12),
                      const SizedBox(width: 2),
                      Text(invoice.destinationCity,
                          style: const TextStyle(color: Colors.white24, fontSize: 11)),
                      if (invoice.issuedAt != null) ...[
                        const Text(' · ', style: TextStyle(color: Colors.white24)),
                        Text(dateFmt.format(invoice.issuedAt!),
                            style: const TextStyle(color: Colors.white24, fontSize: 11)),
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
                        color: Color(0xFF00C896), fontWeight: FontWeight.bold, fontSize: 14)),
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
        ? const Color(0xFF00C896)
        : s == 'pending'
            ? Colors.orange
            : Colors.red;
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 148,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _InvoiceShimmerCard extends StatelessWidget {
  const _InvoiceShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
