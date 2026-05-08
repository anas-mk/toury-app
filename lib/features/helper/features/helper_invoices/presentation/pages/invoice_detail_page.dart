import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/invoice_entities.dart';
import '../cubit/helper_invoices_cubit.dart';
import '../widgets/payment_status_pill.dart';

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
    final palette = AppColors.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        backgroundColor: palette.scaffold,
        body: BlocBuilder<HelperInvoicesCubit, HelperInvoicesState>(
          builder: (context, state) {
            if (state is InvoiceDetailLoading || state is InvoicesInitial) {
              return _buildShimmer(context);
            }
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

  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDetail(BuildContext context, InvoiceDetailEntity d) {
    final dateFmt = DateFormat('MMM d, yyyy  HH:mm');
    final shortDate = DateFormat('MMM d, yyyy');

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: CustomScrollView(
          slivers: [
            _SliverHero(detail: d),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.lg,
                AppSpacing.pageGutter,
                AppSpacing.huge + AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInSlide(
                    delay: const Duration(milliseconds: 80),
                    child: _MetaCard(detail: d, dateFmt: shortDate),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 140),
                    child: const _SectionTitle(
                      'Trip Information',
                      icon: Icons.route_rounded,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 180),
                    child: _TripCard(detail: d, dateFmt: dateFmt),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 220),
                    child: const _SectionTitle(
                      'Price Breakdown',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 260),
                    child: _PriceCard(detail: d),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 320),
                    child: _NetEarningsCard(detail: d),
                  ),
                  if (d.notes != null && d.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 360),
                      child: _NotesCard(notes: d.notes!),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 400),
                    child: _ActionRow(detail: d),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyInvoiceNumber(BuildContext context, String number) {
    HapticService.light();
    Clipboard.setData(ClipboardData(text: number));
    if (!context.mounted) return;
    AppSnackbar.info(context, 'Invoice #$number copied');
  }

  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildShimmer(BuildContext context) {
    final palette = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.huge,
        AppSpacing.pageGutter,
        AppSpacing.xxl,
      ),
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            height: 100,
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sliver Hero ─────────────────────────────────────────────────────────────
class _SliverHero extends StatelessWidget {
  final InvoiceDetailEntity detail;
  const _SliverHero({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 240,
      backgroundColor: palette.scaffold,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: _GlassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => context.pop(),
        ),
      ),
      title: Text(
        'Invoice',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            56,
            AppSpacing.pageGutter,
            AppSpacing.lg,
          ),
          child: _HeaderCard(detail: detail),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final InvoiceDetailEntity detail;
  const _HeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [
                  palette.primary.withValues(alpha: 0.32),
                  palette.primaryStrong.withValues(alpha: 0.18),
                  palette.success.withValues(alpha: 0.18),
                ]
              : [
                  palette.primary.withValues(alpha: 0.95),
                  palette.primaryStrong.withValues(alpha: 0.88),
                  palette.success.withValues(alpha: 0.78),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(
              alpha: palette.isDark ? 0.20 : 0.30,
            ),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
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
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${detail.invoiceNumber}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Earnings',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Money.egp(detail.netAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PaymentStatusPill(status: detail.paymentStatus),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Glass Icon Button ───────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, color: palette.textPrimary, size: 18),
        ),
      ),
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, {required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, color: palette.textSecondary, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ─── Surface Card Wrapper ────────────────────────────────────────────────────
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.18 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Meta Card ───────────────────────────────────────────────────────────────
class _MetaCard extends StatelessWidget {
  final InvoiceDetailEntity detail;
  final DateFormat dateFmt;
  const _MetaCard({required this.detail, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return _SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _MetaItem(
              label: 'Issued',
              value: detail.issuedAt != null
                  ? dateFmt.format(detail.issuedAt!)
                  : '—',
              icon: Icons.event_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: palette.divider,
          ),
          Expanded(
            child: _MetaItem(
              label: 'Paid On',
              value: detail.paidAt != null
                  ? dateFmt.format(detail.paidAt!)
                  : '—',
              icon: Icons.check_circle_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: palette.divider,
          ),
          Expanded(
            child: _MetaItem(
              label: 'Method',
              value: detail.paymentMethod.isEmpty
                  ? '—'
                  : detail.paymentMethod,
              icon: Icons.credit_card_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetaItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Column(
      children: [
        Icon(icon, color: palette.textMuted, size: 16),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Trip Card ───────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final InvoiceDetailEntity detail;
  final DateFormat dateFmt;
  const _TripCard({required this.detail, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.confirmation_number_rounded,
            label: 'Booking',
            value: '#${detail.bookingId}',
          ),
          _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'Destination',
            value: detail.destinationCity.isEmpty ? '—' : detail.destinationCity,
          ),
          _DetailRow(
            icon: Icons.person_rounded,
            label: 'Traveler',
            value: detail.userName.isEmpty ? '—' : detail.userName,
          ),
          if (detail.tripStartTime != null)
            _DetailRow(
              icon: Icons.flag_rounded,
              label: 'Start',
              value: dateFmt.format(detail.tripStartTime!),
            ),
          if (detail.tripEndTime != null)
            _DetailRow(
              icon: Icons.flag_circle_rounded,
              label: 'End',
              value: dateFmt.format(detail.tripEndTime!),
            ),
          if (detail.durationMinutes != null)
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Duration',
              value: '${detail.durationMinutes} min',
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.primarySoft.withValues(
                alpha: palette.isDark ? 0.38 : 0.85,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm + AppSpacing.xs),
            ),
            child: Icon(icon, color: palette.primary, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Price Card ──────────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final InvoiceDetailEntity detail;
  const _PriceCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final pct = (detail.commissionRate * 100).toStringAsFixed(0);

    return _SurfaceCard(
      child: Column(
        children: [
          _PriceRow(
            label: 'Base Price',
            value: Money.egp(detail.basePrice),
          ),
          if (detail.distanceCost > 0)
            _PriceRow(
              label: 'Distance',
              value: Money.egp(detail.distanceCost),
            ),
          if (detail.durationCost > 0)
            _PriceRow(
              label: 'Duration',
              value: Money.egp(detail.durationCost),
            ),
          if (detail.surchargeAmount > 0)
            _PriceRow(
              label: 'Surcharge',
              value: Money.egp(detail.surchargeAmount),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: palette.divider, height: 1),
          ),
          _PriceRow(
            label: 'Subtotal',
            value: Money.egp(detail.subtotal),
            bold: true,
          ),
          _PriceRow(
            label: 'Platform Commission ($pct%)',
            value: '- ${Money.egp(detail.commissionAmount)}',
            color: palette.danger,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: bold ? palette.textPrimary : palette.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? palette.textPrimary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Net Earnings Highlight ──────────────────────────────────────────────────
class _NetEarningsCard extends StatelessWidget {
  final InvoiceDetailEntity detail;
  const _NetEarningsCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.success.withValues(alpha: 0.18),
            palette.success.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
        border: Border.all(
          color: palette.success.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: palette.success,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Net Earnings',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'After platform commission',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Money.egp(detail.netAmount),
            style: theme.textTheme.titleLarge?.copyWith(
              color: palette.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notes ───────────────────────────────────────────────────────────────────
class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt_rounded,
                color: palette.textSecondary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Notes',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row ──────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final InvoiceDetailEntity detail;
  const _ActionRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                final state = context.findAncestorStateOfType<_InvoiceDetailPageState>();
                state?._copyInvoiceNumber(context, detail.invoiceNumber);
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy #'),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.textPrimary,
                side: BorderSide(color: palette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.primary, palette.primaryStrong],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () {
                    HapticService.light();
                    context.pushNamed(
                      'helper-invoice-view',
                      pathParameters: {'id': detail.invoiceId},
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'View Receipt',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
