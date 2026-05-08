import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/utils/jwt_payload.dart';
import '../../domain/entities/invoice_entity.dart';
import '../cubit/user_invoices_cubit.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class UserInvoicesPage extends StatefulWidget {
  const UserInvoicesPage({super.key});

  @override
  State<UserInvoicesPage> createState() => _UserInvoicesPageState();
}

class _UserInvoicesPageState extends State<UserInvoicesPage> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    try {
      final token = sl<AuthService>().getToken();
      final name = JwtPayload.firstName(token);
      if (name != null && name.isNotEmpty) {
        _firstName = name[0].toUpperCase() + name.substring(1);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserInvoicesCubit>()..loadInvoices(),
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(firstName: _firstName),
              Expanded(
                child: BlocBuilder<UserInvoicesCubit, UserInvoicesState>(
                  builder: (context, state) {
                    if (state is UserInvoicesLoading ||
                        state is UserInvoicesInitial) {
                      return const _Skeleton();
                    }
                    if (state is UserInvoicesError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () =>
                            context.read<UserInvoicesCubit>().loadInvoices(),
                      );
                    }
                    if (state is UserInvoicesLoaded) {
                      if (state.invoices.isEmpty) {
                        return const _EmptyState();
                      }
                      return RefreshIndicator.adaptive(
                        color: BrandTokens.primaryBlue,
                        onRefresh: () =>
                            context.read<UserInvoicesCubit>().loadInvoices(),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            // "Invoices" headline
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 40, 24, 28),
                                child: Text(
                                  'Invoices',
                                  style: BrandTokens.heading(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: BrandTokens.primaryBlue,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),

                            // Invoice cards
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 0, 24, 120),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16),
                                    child: _InvoiceCard(
                                        invoice: state.invoices[i]),
                                  ),
                                  childCount: state.invoices.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String? firstName;
  const _TopBar({this.firstName});

  @override
  Widget build(BuildContext context) {
    final initial = (firstName?.isNotEmpty ?? false)
        ? firstName![0].toUpperCase()
        : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: initial != null
                ? Text(
                    initial,
                    style: BrandTokens.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.primaryBlue,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: BrandTokens.primaryBlue,
                    size: 22,
                  ),
          ),

          const Spacer(),

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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.explore_outlined,
                color: BrandTokens.primaryBlue,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Invoice card ──────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        context.pushNamed(
          'user-invoice-detail',
          pathParameters: {'id': invoice.invoiceId},
          extra: invoice,
        );
      },
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: destination + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.destinationCity,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BrandTokens.body(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BrandTokens.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy')
                        .format(invoice.issuedAt.toLocal()),
                    style: BrandTokens.body(
                      fontSize: 14,
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right: amount + status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                  style: BrandTokens.numeric(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: BrandTokens.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(paymentStatus: invoice.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String paymentStatus;
  const _StatusBadge({required this.paymentStatus});

  @override
  Widget build(BuildContext context) {
    final lower = paymentStatus.toLowerCase();
    final isPaid = lower == 'paid';
    final isPending = lower == 'pending';

    final Color bg;
    final Color fg;

    if (isPaid) {
      bg = const Color(0xFFE4E1EA); // surface-variant
      fg = const Color(0xFF464652); // on-surface-variant
    } else if (isPending) {
      bg = const Color(0xFFFFDAD6); // error-container
      fg = const Color(0xFF93000A); // on-error-container
    } else {
      bg = BrandTokens.primaryBlue.withValues(alpha: 0.10);
      fg = BrandTokens.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        _capitalize(paymentStatus),
        style: BrandTokens.heading(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: BrandTokens.primaryBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No invoices yet',
              style: BrandTokens.heading(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your trip invoices will appear here after a booking is completed.',
              textAlign: TextAlign.center,
              style: BrandTokens.body(
                  fontSize: 13, color: BrandTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
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
              'Could not load invoices',
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

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7EAF6),
      highlightColor: const Color(0xFFF6F8FE),
      period: const Duration(milliseconds: 1400),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        children: [
          // Headline skeleton
          Container(
            width: 130,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 28),
          // Card skeletons
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
