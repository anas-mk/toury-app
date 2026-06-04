import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/ratings/pending_rating_tracker.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../user_booking/presentation/cubits/booking_details_cubit.dart';
import '../cubit/user_ratings_cubit.dart';
import '../cubit/user_ratings_state.dart';
import 'rating_form.dart';

/// Phase 4 — globally-mounted, non-dismissible mandatory rating popup.
///
/// Usage: call [MandatoryRatingOverlay.bind] once at app startup with the
/// root navigator key. The overlay listens to
/// [PendingRatingTracker.changes] and shows itself whenever the set of
/// pending bookings becomes non-empty. Strict no-skip policy: there is
/// no skip button. The user must submit (>=1 star) to dismiss.
///
/// Cold-start behaviour: after [bind] is called, the overlay reads the
/// tracker once and re-shows immediately if the set is non-empty.
class MandatoryRatingOverlay {
  MandatoryRatingOverlay._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static StreamSubscription<Set<String>>? _sub;
  static bool _showing = false;
  static String? _showingFor;

  static void bind(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _sub?.cancel();
    final tracker = sl<PendingRatingTracker>();
    _sub = tracker.changes.listen((set) => _maybeShow(set));
    // Cold-start: re-show if anything is already pending.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShow(tracker.peekPending());
    });
  }

  static Future<void> _maybeShow(Set<String> pending) async {
    if (_showing) return;
    if (pending.isEmpty) return;
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null) return;
    final bookingId = pending.first;
    _showing = true;
    _showingFor = bookingId;
    try {
      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        useRootNavigator: true,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (dialogContext) => _RatingDialog(
          bookingId: bookingId,
          // Capture dialogContext here — stable across async gaps,
          // unlike the BlocConsumer context which may go stale.
          onClose: () {
            if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          },
        ),
      );
    } finally {
      _showing = false;
      _showingFor = null;
      // After a successful submit the tracker emits the new set; re-check
      // in case more bookings remain pending.
      final tracker = sl<PendingRatingTracker>();
      final next = tracker.peekPending();
      if (next.isNotEmpty) {
        // Schedule the next dialog on the next frame so the previous
        // route is fully popped first.
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow(next));
      }
    }
  }

  /// For tests / debug.
  @visibleForTesting
  static String? get currentlyShowingFor => _showingFor;
}

// ============================================================================
//  DIALOG
// ============================================================================

class _RatingDialog extends StatelessWidget {
  final String bookingId;
  final VoidCallback onClose;
  const _RatingDialog({required this.bookingId, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<UserRatingsCubit>()),
        BlocProvider(
          create: (_) => sl<BookingDetailsCubit>()..loadDetails(bookingId),
        ),
      ],
      child: PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: const Color(0xFFFAF8F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: _RatingDialogBody(bookingId: bookingId, onClose: onClose),
        ),
      ),
    );
  }
}

class _RatingDialogBody extends StatefulWidget {
  final String bookingId;
  final VoidCallback onClose;
  const _RatingDialogBody({required this.bookingId, required this.onClose});

  @override
  State<_RatingDialogBody> createState() => _RatingDialogBodyState();
}

class _RatingDialogBodyState extends State<_RatingDialogBody> {
  final GlobalKey<RatingFormState> _formKey = GlobalKey<RatingFormState>();
  int _stars = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserRatingsCubit, UserRatingsState>(
      listener: (context, state) async {
        if (state is RatingSuccess && !_submitted) {
          _submitted = true;
          // Mark submitted first so the overlay doesn't re-show.
          await sl<PendingRatingTracker>().markSubmitted(widget.bookingId);
          // Brief success-animation delay, then close via the stable
          // dialogContext callback (avoids stale-context / mounted issues).
          await Future<void>.delayed(const Duration(milliseconds: 450));
          widget.onClose();
        } else if (state is RatingError) {
          final msg = state.message.toLowerCase();
          // If the booking was already rated (e.g. submitted via RateBookingPage
          // in a previous session), remove it from pending and close the overlay
          // so the user is not stuck in an unsubmittable dialog.
          if (msg.contains('already') || msg.contains('rated')) {
            await sl<PendingRatingTracker>().markSubmitted(widget.bookingId);
            await Future<void>.delayed(const Duration(milliseconds: 300));
            widget.onClose();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: BrandTokens.dangerSos,
                behavior: SnackBarBehavior.floating,
                content: Text(state.message),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final loading = state is RatingLoading;
        final canSubmit = _stars >= 1 && !loading && !_submitted;
        final showSuccess = state is RatingSuccess || _submitted;

        final kbInset = MediaQuery.viewInsetsOf(context).bottom;
        final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.86;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: kbInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: showSuccess
                  ? const _SuccessBlock()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DialogHero(bookingId: widget.bookingId),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: BrandTokens.primaryBlue
                                    .withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                          child: RatingForm(
                            key: _formKey,
                            compact: true,
                            disabled: loading,
                            onStarsChanged: (s) => setState(() => _stars = s),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _DialogSubmitButton(
                          enabled: canSubmit,
                          loading: loading,
                          onPressed: canSubmit
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  final form = _formKey.currentState;
                                  context
                                      .read<UserRatingsCubit>()
                                      .submitRating(
                                        bookingId: widget.bookingId,
                                        stars: _stars,
                                        comment:
                                            form?.comment.trim() ?? '',
                                        tags: form?.selectedTags ?? const [],
                                      );
                                }
                              : null,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Rating is required to finish your trip.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF767683),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog hero — compact avatar + headline.
// ─────────────────────────────────────────────────────────────────────────────

class _DialogHero extends StatelessWidget {
  final String bookingId;
  const _DialogHero({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
      builder: (context, state) {
        String? avatar;
        String firstName = 'your helper';
        if (state is BookingDetailsLoaded) {
          avatar = state.helper.profileImageUrl;
          firstName = state.helper.name.split(' ').first;
        }
        return Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: BrandTokens.primaryBlue.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatar != null
                    ? AppNetworkImage(
                        imageUrl: avatar,
                        width: 78,
                        height: 78,
                        borderRadius: 39,
                      )
                    : Container(
                        color: const Color(0xFFEEEAFB),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: BrandTokens.primaryBlue,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state is BookingDetailsLoaded
                  ? 'How was your trip with $firstName?'
                  : 'How was your trip?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000568),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your feedback helps us maintain exceptional experiences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xCC464652),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit button — pill with gradient + arrow, matches the page CTA.
// ─────────────────────────────────────────────────────────────────────────────

class _DialogSubmitButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  const _DialogSubmitButton({
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
        height: 56,
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
                color: BrandTokens.primaryBlue.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Submit Review',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
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
// Success block — green check + thank-you copy.
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessBlock extends StatefulWidget {
  const _SuccessBlock();

  @override
  State<_SuccessBlock> createState() => _SuccessBlockState();
}

class _SuccessBlockState extends State<_SuccessBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _ctl,
              curve: Curves.easeOutBack,
            ),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: BrandTokens.successGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BrandTokens.successGreen.withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Thanks for your feedback!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000568),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your rating helps the next traveler choose the right helper.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xCC464652),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
