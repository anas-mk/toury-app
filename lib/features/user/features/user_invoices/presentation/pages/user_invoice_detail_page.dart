import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/get_invoice_detail_usecase.dart';

class UserInvoiceDetailPage extends StatefulWidget {
  final String invoiceId;
  final InvoiceEntity? initialInvoice;

  const UserInvoiceDetailPage({
    super.key,
    required this.invoiceId,
    this.initialInvoice,
  });

  @override
  State<UserInvoiceDetailPage> createState() => _UserInvoiceDetailPageState();
}

class _UserInvoiceDetailPageState extends State<UserInvoiceDetailPage> {
  late Future<InvoiceEntity> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<InvoiceEntity> _load() async {
    final result =
        await sl<GetInvoiceDetailUseCase>()(widget.invoiceId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (invoice) => invoice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => context.pop()),
            Expanded(
              child: FutureBuilder<InvoiceEntity>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _Skeleton();
                  }
                  if (snap.hasError) {
                    return _ErrorView(
                      message: snap.error.toString().replaceFirst('Exception: ', ''),
                      onRetry: () => setState(() => _future = _load()),
                    );
                  }
                  return _Body(invoice: snap.data!, invoiceId: widget.invoiceId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: BrandTokens.primaryBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // RAFIQ wordmark
          const Text(
            'RAFIQ',
            style: TextStyle(
              inherit: false,
              fontFamily: 'PermanentMarker',
              fontSize: 28,
              color: BrandTokens.primaryBlue,
            ),
          ),

          const Spacer(),

          // Explore icon
          const Icon(
            Icons.explore_outlined,
            color: BrandTokens.primaryBlue,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final InvoiceEntity invoice;
  final String invoiceId;
  const _Body({required this.invoice, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Receipt label + headline ──────────────────────────────────
          Text(
            'RECEIPT',
            style: BrandTokens.heading(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandTokens.warningAmber,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Invoice #${invoice.invoiceNumber}',
            style: BrandTokens.heading(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: BrandTokens.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 28),

          // ── Helper card ───────────────────────────────────────────────
          _HelperCard(helperName: invoice.helperName),

          const SizedBox(height: 20),

          // ── Itemized breakdown card ───────────────────────────────────
          _BreakdownCard(invoice: invoice),

          const SizedBox(height: 28),

          // ── View Printable Invoice button ─────────────────────────────
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pushNamed(
                  'user-invoice-view',
                  pathParameters: {'id': invoiceId},
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandTokens.primaryBlue,
                side: const BorderSide(color: BrandTokens.primaryBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              icon: const Icon(Icons.print_outlined, size: 20),
              label: Text(
                'View Printable Invoice',
                style: BrandTokens.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: BrandTokens.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper card ──────────────────────────────────────────────────────────────

class _HelperCard extends StatelessWidget {
  final String helperName;
  const _HelperCard({required this.helperName});

  @override
  Widget build(BuildContext context) {
    final initial = helperName.isNotEmpty ? helperName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E1EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B237E),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: BrandTokens.heading(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: BrandTokens.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                helperName.isEmpty ? 'Guide' : helperName,
                style: BrandTokens.body(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: BrandTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your Guide',
                style: BrandTokens.body(
                  fontSize: 13,
                  color: BrandTokens.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Breakdown card ───────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const _BreakdownCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dur = invoice.durationInMinutes;
    final dist = invoice.tripDistanceKm;
    final surcharge = invoice.instantSurchargeAmount ?? 0;

    final items = <({String label, double amount})>[
      if (invoice.basePrice != null)
        (label: 'Base price', amount: invoice.basePrice!),
      if (dist != null && invoice.distanceCost != null)
        (
          label:
              'Distance (${dist % 1 == 0 ? dist.toInt() : dist.toStringAsFixed(1)} km)',
          amount: invoice.distanceCost!
        ),
      if (dur != null && invoice.durationCost != null)
        (label: 'Duration (${_durLabel(dur)})', amount: invoice.durationCost!),
      if (surcharge > 0)
        (label: 'Instant surcharge', amount: surcharge),
    ];

    // Sequence number watermark: invoice number last 2 digits or index
    final seq = invoice.invoiceNumber.replaceAll(RegExp(r'\D'), '');
    final watermark =
        seq.length >= 2 ? seq.substring(seq.length - 2) : seq.padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E4DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B237E),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative watermark number
          Positioned(
            right: -16,
            top: -20,
            child: Text(
              watermark,
              style: TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEFECF5).withValues(alpha: 0.8),
                height: 1,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line items
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No itemized breakdown available.',
                    style: BrandTokens.body(
                        fontSize: 14, color: BrandTokens.textSecondary),
                  ),
                )
              else
                ...items.map((item) => _LineItem(
                      label: item.label,
                      amount: item.amount,
                      currency: invoice.currency,
                      isLast: item == items.last,
                    )),

              // Divider
              Container(
                height: 1,
                color: BrandTokens.primaryBlue,
                margin: const EdgeInsets.symmetric(vertical: 16),
              ),

              // Total row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: BrandTokens.body(
                      fontSize: 17,
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                    style: BrandTokens.numeric(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _durLabel(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isLast;
  const _LineItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: const Color(0xFFE4E1EA).withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: BrandTokens.body(
              fontSize: 15,
              color: BrandTokens.textSecondary,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} $currency',
            style: BrandTokens.body(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: BrandTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7EAF6),
      highlightColor: const Color(0xFFF6F8FE),
      period: const Duration(milliseconds: 1400),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(80, 14, radius: 6),
            const SizedBox(height: 10),
            _box(220, 30, radius: 8),
            const SizedBox(height: 28),
            _box(double.infinity, 88, radius: 20),
            const SizedBox(height: 20),
            _box(double.infinity, 220, radius: 20),
          ],
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 4}) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}

// ─── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: BrandTokens.dangerSos),
            const SizedBox(height: 12),
            Text(
              'Could not load invoice',
              style: BrandTokens.heading(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                  fontSize: 13, color: BrandTokens.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
