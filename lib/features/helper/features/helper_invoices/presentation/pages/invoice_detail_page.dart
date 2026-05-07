import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
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
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        appBar: BasicAppBar(
          title: 'Invoice',
          centerTitle: false,
          actions: [
            BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
              builder: (context, state) {
                if (state is! InvoiceDetailLoaded) {
                  return const SizedBox.shrink();
                }
                final palette = AppColors.of(context);
                return IconButton(
                  tooltip: 'Copy invoice number',
                  icon: Icon(Icons.share_rounded, color: palette.textPrimary),
                  onPressed: () =>
                      _copyInvoiceNumber(context, state.detail.invoiceNumber),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
          builder: (context, state) {
            if (state is InvoiceDetailLoading) return _buildShimmer(context);
            if (state is InvoicesError) {
              return AppErrorState(
                title: 'Could not load invoice',
                message: state.message,
                onRetry: () => _cubit.loadDetail(widget.invoiceId),
              );
            }
            if (state is InvoiceDetailLoaded) {
              return _buildDetail(context, state.detail);
            }
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
    final palette = AppColors.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
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
                          Text(
                            'INVOICE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.textSecondary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${d.invoiceNumber}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _StatusPill(status: d.paymentStatus),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: palette.border),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          label: 'Issued',
                          value: d.issuedAt != null
                              ? shortDate.format(d.issuedAt!)
                              : '—',
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          label: 'Paid On',
                          value: d.paidAt != null
                              ? shortDate.format(d.paidAt!)
                              : '—',
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          label: 'Method',
                          value: d.paymentMethod.isEmpty
                              ? '—'
                              : d.paymentMethod,
                        ),
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
                  _DetailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Booking ID',
                    value: d.bookingId,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Destination',
                    value: d.destinationCity,
                  ),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Traveler',
                    value: d.userName,
                  ),
                  if (d.tripStartTime != null)
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Start',
                      value: dateFmt.format(d.tripStartTime!),
                    ),
                  if (d.tripEndTime != null)
                    _DetailRow(
                      icon: Icons.flag_rounded,
                      label: 'End',
                      value: dateFmt.format(d.tripEndTime!),
                    ),
                  if (d.durationMinutes != null)
                    _DetailRow(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: '${d.durationMinutes} min',
                    ),
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
                  _PriceRow(
                    label: 'Base Price',
                    value: '${d.currency} ${fmt.format(d.basePrice)}',
                  ),
                  if (d.distanceCost > 0)
                    _PriceRow(
                      label: 'Distance Cost',
                      value: '${d.currency} ${fmt.format(d.distanceCost)}',
                    ),
                  if (d.durationCost > 0)
                    _PriceRow(
                      label: 'Duration Cost',
                      value: '${d.currency} ${fmt.format(d.durationCost)}',
                    ),
                  if (d.surchargeAmount > 0)
                    _PriceRow(
                      label: 'Surcharge',
                      value: '${d.currency} ${fmt.format(d.surchargeAmount)}',
                    ),
                  Divider(height: AppSpacing.pageGutter, color: palette.border),
                  _PriceRow(
                    label: 'Subtotal',
                    value: '${d.currency} ${fmt.format(d.subtotal)}',
                    bold: true,
                  ),
                  _PriceRow(
                    label:
                        'Commission (${(d.commissionRate * 100).toStringAsFixed(0)}%)',
                    value: '- ${d.currency} ${fmt.format(d.commissionAmount)}',
                    color: palette.danger,
                  ),
                  Divider(height: AppSpacing.pageGutter, color: palette.border),
                  // Net Earnings (highlighted)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: palette.successSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: palette.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: palette.success,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Your Earnings',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: palette.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${d.currency} ${fmt.format(d.netAmount)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Actions ──────────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _copyInvoiceNumber(context, d.invoiceNumber),
                    icon: Icon(
                      Icons.copy_rounded,
                      size: AppSize.iconSm,
                      color: palette.textPrimary,
                    ),
                    label: Text(
                      'Copy #',
                      style: TextStyle(color: palette.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md + AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.sm + AppSpacing.xs,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => context.pushNamed(
                      'helper-invoice-view',
                      pathParameters: {'id': d.invoiceId},
                    ),
                    icon: Icon(
                      Icons.receipt_long_rounded,
                      size: AppSize.iconSm,
                      color: palette.onPrimary,
                    ),
                    label: Text(
                      'View Receipt',
                      style: TextStyle(color: palette.onPrimary),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md + AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.sm + AppSpacing.xs,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  void _copyInvoiceNumber(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    if (!context.mounted) return;
    AppSnackbar.info(context, 'Invoice #$number copied');
  }

  Widget _buildShimmer(BuildContext context) {
    final palette = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          height: 100,
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.xs),
          ),
        ),
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
    final palette = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
        border: Border.all(color: palette.border),
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
    final palette = AppColors.of(context);

    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: palette.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final s = status.toLowerCase();

    late final Color color;
    switch (s) {
      case 'paid':
        color = palette.success;
        break;
      case 'pending':
        color = palette.warning;
        break;
      default:
        color = palette.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm + AppSpacing.xs),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
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
    final palette = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted, size: AppSize.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: bold ? palette.textPrimary : palette.textSecondary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? palette.textPrimary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
