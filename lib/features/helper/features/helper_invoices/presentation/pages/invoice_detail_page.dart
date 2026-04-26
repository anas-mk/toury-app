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

class InvoiceDetailPage extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late final HelperInvoicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperInvoicesCubit>()..loadDetail(widget.invoiceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Invoice'),
          actions: [
            BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
              builder: (context, state) {
                if (state is! InvoiceDetailLoaded) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _copyInvoiceNumber(context, state.detail.invoiceNumber),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
          builder: (context, state) {
            if (state is InvoiceDetailLoading) return _buildShimmer(context);
            if (state is InvoicesError) return _buildError(context, state.message);
            if (state is InvoiceDetailLoaded) return _buildDetail(context, state.detail);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, InvoiceDetailEntity d) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, yyyy  HH:mm');
    final shortDate = DateFormat('MMM d, yyyy');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      children: [
        // ── Invoice Header Card ─────────────────────────────────────────────
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INVOICE', style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 10, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('#${d.invoiceNumber}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _StatusPill(status: d.paymentStatus),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AppColor.lightBorder),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(label: 'Issued', value: d.issuedAt != null ? shortDate.format(d.issuedAt!) : '—'),
                  ),
                  Expanded(
                    child: _InfoItem(label: 'Paid On', value: d.paidAt != null ? shortDate.format(d.paidAt!) : '—'),
                  ),
                  Expanded(
                    child: _InfoItem(label: 'Method', value: d.paymentMethod.isEmpty ? '—' : d.paymentMethod),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Trip Info ────────────────────────────────────────────────────────
        const _SectionTitle('Trip Information'),
        const SizedBox(height: 10),
        _GlassCard(
          child: Column(
            children: [
              _DetailRow(icon: Icons.confirmation_number_outlined, label: 'Booking ID', value: d.bookingId),
              _DetailRow(icon: Icons.location_on_outlined, label: 'Destination', value: d.destinationCity),
              _DetailRow(icon: Icons.person_outline_rounded, label: 'Traveler', value: d.userName),
              if (d.tripStartTime != null)
                _DetailRow(icon: Icons.schedule_rounded, label: 'Start', value: dateFmt.format(d.tripStartTime!)),
              if (d.tripEndTime != null)
                _DetailRow(icon: Icons.flag_rounded, label: 'End', value: dateFmt.format(d.tripEndTime!)),
              if (d.durationMinutes != null)
                _DetailRow(icon: Icons.timer_outlined, label: 'Duration', value: '${d.durationMinutes} min'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Price Breakdown ──────────────────────────────────────────────────
        const _SectionTitle('Price Breakdown'),
        const SizedBox(height: 10),
        _GlassCard(
          child: Column(
            children: [
              _PriceRow(label: 'Base Price', value: '${d.currency} ${fmt.format(d.basePrice)}'),
              if (d.distanceCost > 0)
                _PriceRow(label: 'Distance Cost', value: '${d.currency} ${fmt.format(d.distanceCost)}'),
              if (d.durationCost > 0)
                _PriceRow(label: 'Duration Cost', value: '${d.currency} ${fmt.format(d.durationCost)}'),
              if (d.surchargeAmount > 0)
                _PriceRow(label: 'Surcharge', value: '${d.currency} ${fmt.format(d.surchargeAmount)}'),
              Divider(color: AppColor.lightBorder, height: 24),
              _PriceRow(label: 'Subtotal', value: '${d.currency} ${fmt.format(d.subtotal)}', bold: true),
              _PriceRow(
                label: 'Commission (${(d.commissionRate * 100).toStringAsFixed(0)}%)',
                value: '- ${d.currency} ${fmt.format(d.commissionAmount)}',
                color: AppColor.errorColor,
              ),
              Divider(color: AppColor.lightBorder, height: 24),
              // Net Earnings (highlighted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: AppColor.accentColor, size: 18),
                        SizedBox(width: 8),
                        Text('Your Earnings',
                            style: TextStyle(
                                color: AppColor.accentColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    Text('${d.currency} ${fmt.format(d.netAmount)}',
                        style: const TextStyle(
                            color: AppColor.accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Actions ──────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyInvoiceNumber(context, d.invoiceNumber),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy #'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/helper/invoice-view/${d.invoiceId}'),
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('View Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _copyInvoiceNumber(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice #$number copied'),
        backgroundColor: theme.dialogBackgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),
          Text('Invoice not found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Text(title,
        style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12,
            fontWeight: FontWeight.w600, letterSpacing: 0.5));
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final color = s == 'paid'
        ? AppColor.accentColor
        : s == 'pending'
            ? Colors.orange
            : AppColor.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white24 : Colors.black26, size: 16),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _PriceRow({required this.label, required this.value, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: color ?? (isDark ? Colors.white : Colors.black),
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
