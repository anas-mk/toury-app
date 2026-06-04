import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/user/features/user_ratings/presentation/cubit/user_ratings_cubit.dart';
import 'package:toury/features/user/features/user_ratings/presentation/cubit/user_ratings_state.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/ratings/pending_rating_tracker.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../user_booking/presentation/cubits/booking_details_cubit.dart';
import '../widgets/rating_form.dart';

/// Full-screen rating experience shown after a trip ends.
///
/// Pulls booking + helper info via [BookingDetailsCubit] so we can
/// greet the user with the helper's photo and first name ("How was
/// your trip with Omar?"). The form itself lives in [RatingForm]
/// which is also reused inside [MandatoryRatingOverlay] so both
/// surfaces stay visually in lock-step.
class RateBookingPage extends StatelessWidget {
  final String bookingId;

  const RateBookingPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<UserRatingsCubit>()),
        BlocProvider(
          create: (_) => sl<BookingDetailsCubit>()..loadDetails(bookingId),
        ),
      ],
      child: BlocListener<UserRatingsCubit, UserRatingsState>(
        listener: (context, state) async {
          if (state is RatingSuccess) {
            await sl<PendingRatingTracker>().markSubmitted(bookingId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you for your feedback!')),
            );
            context.go('/home');
          } else if (state is RatingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: BrandTokens.dangerRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: PopScope(
          canPop: false,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemStatusBarContrastEnforced: false,
            ),
            child: Scaffold(
              backgroundColor: _ratingBg,
              extendBodyBehindAppBar: true,
              body: _RateBookingBody(bookingId: bookingId),
            ),
          ),
        ),
      ),
    );
  }
}

const Color _ratingBg = Color(0xFFFAF8F4);

class _RateBookingBody extends StatefulWidget {
  final String bookingId;
  const _RateBookingBody({required this.bookingId});

  @override
  State<_RateBookingBody> createState() => _RateBookingBodyState();
}

class _RateBookingBodyState extends State<_RateBookingBody> {
  final GlobalKey<RatingFormState> _formKey = GlobalKey<RatingFormState>();
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        // Soft noise / off-white background already painted by Scaffold.
        // We layer a subtle gradient halo behind the avatar so the hero
        // feels lifted off the page (matches the warm-ambient mock).
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: const _HaloPainter()),
          ),
        ),
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopBar(topInset: topPad),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
                builder: (context, state) {
                  String helperName = 'your helper';
                  String? avatar;
                  if (state is BookingDetailsLoaded) {
                    helperName = state.helper.name;
                    avatar = state.helper.profileImageUrl;
                  }
                  final firstName = helperName.split(' ').first;
                  return _Hero(
                    helperFirstName: firstName,
                    avatarUrl: avatar,
                    loading: state is BookingDetailsLoading ||
                        state is BookingDetailsInitial,
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _PremiumCard(
                  child: RatingForm(
                    key: _formKey,
                    onStarsChanged: (s) => setState(() => _stars = s),
                  ),
                ),
              ),
            ),
            // Tail spacer so the floating Submit button can't cover the
            // last input on small screens with the keyboard open.
            SliverToBoxAdapter(
              child: SizedBox(height: 140 + bottomPad),
            ),
          ],
        ),
        // Bottom CTA — fades over the scroll content with a soft gradient.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _SubmitBar(
            bookingId: widget.bookingId,
            stars: _stars,
            commentOf: () => _formKey.currentState?.comment ?? '',
            tagsOf: () => _formKey.currentState?.selectedTags ?? const [],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — just a close (X) button that routes home.
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final double topInset;
  const _TopBar({required this.topInset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/home');
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Color(0xFF464652),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — avatar, headline, subtitle.
// ─────────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final String helperFirstName;
  final String? avatarUrl;
  final bool loading;
  const _Hero({
    required this.helperFirstName,
    required this.avatarUrl,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          // Avatar.
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? AppNetworkImage(
                      imageUrl: avatarUrl,
                      width: 106,
                      height: 106,
                      borderRadius: 53,
                    )
                  : Container(
                      color: const Color(0xFFEEEAFB),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 56,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loading
                ? 'How was your trip?'
                : 'How was your trip with $helperFirstName?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000568),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your feedback helps us maintain exceptional experiences.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: Color(0xCC464652),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium card — frosted white container that wraps the form.
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  final Widget child;
  const _PremiumCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          const BoxShadow(
            color: Color(0x05000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit bar — big pill button anchored to the bottom of the screen.
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final String bookingId;
  final int stars;
  final String Function() commentOf;
  final List<String> Function() tagsOf;
  const _SubmitBar({
    required this.bookingId,
    required this.stars,
    required this.commentOf,
    required this.tagsOf,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00FAF8F4),
            Color(0xE6FAF8F4),
            _ratingBg,
          ],
          stops: [0.0, 0.35, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 36, 20, 20 + bottomPad),
      child: BlocBuilder<UserRatingsCubit, UserRatingsState>(
        builder: (context, state) {
          final loading = state is RatingLoading;
          final enabled = stars >= 1 && !loading;
          return _BigSubmitButton(
            label: 'Submit Review',
            loading: loading,
            enabled: enabled,
            onPressed: enabled
                ? () {
                    HapticFeedback.mediumImpact();
                    context.read<UserRatingsCubit>().submitRating(
                          bookingId: bookingId,
                          stars: stars,
                          comment: commentOf().trim(),
                          tags: tagsOf(),
                        );
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _BigSubmitButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  const _BigSubmitButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || loading ? 1.0 : 0.55,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF000568), Color(0xFF2A33A8)],
            ),
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: onPressed,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.6,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Soft halo behind the hero — gives the page an "ambient glow" feel.
// ─────────────────────────────────────────────────────────────────────────────

class _HaloPainter extends CustomPainter {
  const _HaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          BrandTokens.primaryBlue.withValues(alpha: 0.07),
          BrandTokens.primaryBlue.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.16),
          radius: size.width * 0.7,
        ),
      );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.16),
      size.width * 0.7,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
