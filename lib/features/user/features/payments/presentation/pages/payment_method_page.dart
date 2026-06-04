import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy       = Color(0xFF000668);
const _kBlue       = Color(0xFF4851C4);
const _kSurface    = Color(0xFFFBF8FF);
const _kCard       = Color(0xFFFFFFFF);
const _kMuted      = Color(0xFF767683);
const _kOnSurface  = Color(0xFF1A1B25);
const _kOutline    = Color(0xFFC6C5D3);
const _kContainer  = Color(0xFFF4F2FF);

const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Payment method selection screen.
///
/// For deposit payments (the typical scheduled-trip flow) only card
/// payment is accepted — cash is intentionally hidden because the
/// deposit must be secured before the trip date.
class PaymentMethodPage extends StatefulWidget {
  final String bookingId;

  /// When [depositOnly] is true, the Cash option is hidden and a
  /// small explanatory note is shown. Defaults to true since deposits
  /// are the primary reason to reach this page.
  final bool depositOnly;

  const PaymentMethodPage({
    super.key,
    required this.bookingId,
    this.depositOnly = true,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  // Only card payment is supported for deposits, so we hard-code the
  // selection and don't render the cash tile at all.
  final String _selectedMethod = 'MockCard';

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          context.go(AppRouter.paymentSuccess, extra: widget.bookingId);
        } else if (state is PaymentInitiated) {
          context.push(AppRouter.paymentProcessing, extra: state.payment);
        } else if (state is PaymentFailed) {
          AppSnackbar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: _kSurface,
        body: Stack(
          children: [
            // ── Scrollable body ─────────────────────────────────────────
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPad + 72)),

                // ── Hero section ──────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: _PageHero(),
                  ),
                ),

                // ── Card method tile ──────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _MethodTile(
                      id: 'MockCard',
                      icon: Icons.credit_card_rounded,
                      title: 'Credit / Debit Card',
                      subtitle: 'Secure online payment via card gateway',
                      selected: _selectedMethod == 'MockCard',
                      onTap: null, // only option — always selected
                    ),
                  ),
                ),

                // Deposit-only note
                if (widget.depositOnly)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _DepositNote(),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 120 + bottomPad)),
              ],
            ),

            // ── Fixed header ────────────────────────────────────────────
            _Header(topPad: topPad),

            // ── Pay button ──────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PayBar(
                bookingId: widget.bookingId,
                method: _selectedMethod,
                bottomPad: bottomPad,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
        decoration: BoxDecoration(
          color: _kSurface.withValues(alpha: 0.94),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E1B237E),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.pop();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0E1B237E),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _kOnSurface,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Payment',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _PageHero extends StatelessWidget {
  const _PageHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: _kGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kNavy.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Secure Payment',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _kNavy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose how you\'d like to pay your deposit.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: _kMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'PAYMENT METHOD',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _kMuted,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ── Method tile ───────────────────────────────────────────────────────────────

class _MethodTile extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _kContainer : _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kBlue : _kOutline.withValues(alpha: 0.6),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kNavy.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0x081B237E),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? _kNavy.withValues(alpha: 0.08)
                    : const Color(0xFFF4F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? _kNavy : _kMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? _kNavy : _kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kNavy : Colors.transparent,
                border: Border.all(
                  color: selected ? _kNavy : _kOutline,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Deposit-only note ─────────────────────────────────────────────────────────

class _DepositNote extends StatelessWidget {
  const _DepositNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: _kBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Deposits must be paid by card to secure your booking.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: _kBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pay bar ───────────────────────────────────────────────────────────────────

class _PayBar extends StatelessWidget {
  final String bookingId;
  final String method;
  final double bottomPad;

  const _PayBar({
    required this.bookingId,
    required this.method,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B237E),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          final loading = state is PaymentLoading;
          return GestureDetector(
            onTap: loading
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    context.read<PaymentCubit>().initiatePayment(
                          bookingId,
                          method,
                        );
                  },
            child: AnimatedOpacity(
              opacity: loading ? 0.7 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: _kGradient,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: _kNavy.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pay Deposit Securely',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
