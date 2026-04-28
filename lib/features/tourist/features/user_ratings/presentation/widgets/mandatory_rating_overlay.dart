import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/ratings/pending_rating_tracker.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../cubit/user_ratings_cubit.dart';
import '../cubit/user_ratings_state.dart';

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
        builder: (dialogContext) => _RatingDialog(bookingId: bookingId),
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
  const _RatingDialog({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserRatingsCubit>(),
      child: PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: BrandTokens.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: _RatingDialogBody(bookingId: bookingId),
        ),
      ),
    );
  }
}

class _RatingDialogBody extends StatefulWidget {
  final String bookingId;
  const _RatingDialogBody({required this.bookingId});

  @override
  State<_RatingDialogBody> createState() => _RatingDialogBodyState();
}

class _RatingDialogBodyState extends State<_RatingDialogBody> {
  int _stars = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  final List<String> _selectedTags = [];
  bool _submitted = false;

  static const List<_TagSpec> _tagSpecs = [
    _TagSpec('Friendly', Icons.sentiment_satisfied_rounded),
    _TagSpec('Professional', Icons.workspace_premium_rounded),
    _TagSpec('Knowledgeable', Icons.lightbulb_rounded),
    _TagSpec('Punctual', Icons.schedule_rounded),
    _TagSpec('Great Tips', Icons.tips_and_updates_rounded),
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserRatingsCubit, UserRatingsState>(
      listener: (context, state) async {
        if (state is RatingSuccess && !_submitted) {
          _submitted = true;
          await sl<PendingRatingTracker>().markSubmitted(widget.bookingId);
          if (!context.mounted) return;
          // Tiny pause so users see the success tick before pop.
          await Future<void>.delayed(const Duration(milliseconds: 450));
          if (!context.mounted) return;
          Navigator.of(context, rootNavigator: true).pop();
        } else if (state is RatingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: BrandTokens.dangerSos,
              behavior: SnackBarBehavior.floating,
              content: Text(state.message),
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is RatingLoading;
        final canSubmit = _stars >= 1 && !loading && !_submitted;
        final showSuccess = state is RatingSuccess || _submitted;

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSuccess) const _SuccessBlock() else _Header(stars: _stars),
              if (!showSuccess) ...[
                const SizedBox(height: 18),
                _StarsRow(
                  value: _stars,
                  onChanged: loading
                      ? null
                      : (next) => setState(() => _stars = next),
                ),
                const SizedBox(height: 16),
                if (_stars >= 1) ...[
                  Text(
                    'WHAT STOOD OUT?',
                    style: BrandTypography.overline(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tagSpecs.map((t) {
                      final selected = _selectedTags.contains(t.label);
                      return _TagChip(
                        label: t.label,
                        icon: t.icon,
                        selected: selected,
                        onTap: loading
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (selected) {
                                    _selectedTags.remove(t.label);
                                  } else {
                                    _selectedTags.add(t.label);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentCtrl,
                    enabled: !loading,
                    maxLines: 3,
                    maxLength: 240,
                    decoration: InputDecoration(
                      hintText: 'Optional: share more (240 chars max)',
                      hintStyle: BrandTypography.caption(
                        color: BrandTokens.textMuted,
                      ),
                      filled: true,
                      fillColor: BrandTokens.bgSoft,
                      contentPadding: const EdgeInsets.all(12),
                      counterStyle: BrandTypography.overline(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: BrandTokens.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _SubmitButton(
                  loading: loading,
                  enabled: canSubmit,
                  onPressed: canSubmit
                      ? () {
                          HapticFeedback.lightImpact();
                          context.read<UserRatingsCubit>().submitRating(
                                bookingId: widget.bookingId,
                                stars: _stars,
                                comment: _commentCtrl.text.trim(),
                                tags: _selectedTags,
                              );
                        }
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  'Rating is required to finish your trip.',
                  textAlign: TextAlign.center,
                  style: BrandTypography.caption(
                    color: BrandTokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
//  SUB-WIDGETS
// ============================================================================

class _Header extends StatelessWidget {
  final int stars;
  const _Header({required this.stars});

  @override
  Widget build(BuildContext context) {
    final headline = stars == 0
        ? 'Rate your helper'
        : stars >= 4
            ? 'Glad you enjoyed it!'
            : stars >= 3
                ? 'Tell us more'
                : 'We hear you';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: BrandTokens.amberGradient,
            shape: BoxShape.circle,
            boxShadow: BrandTokens.ctaAmberGlow,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.star_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: BrandTypography.title(weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Your trip is complete. Help future travelers by sharing your experience.',
          textAlign: TextAlign.center,
          style: BrandTypography.caption(),
        ),
      ],
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  const _StarsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return _StarTap(
          filled: filled,
          index: i,
          onTap: onChanged == null ? null : () => onChanged!(i + 1),
        );
      }),
    );
  }
}

class _StarTap extends StatefulWidget {
  final bool filled;
  final int index;
  final VoidCallback? onTap;
  const _StarTap({
    required this.filled,
    required this.index,
    required this.onTap,
  });

  @override
  State<_StarTap> createState() => _StarTapState();
}

class _StarTapState extends State<_StarTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    lowerBound: 0,
    upperBound: 1,
    value: widget.filled ? 1 : 0,
  );

  @override
  void didUpdateWidget(_StarTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filled != oldWidget.filled) {
      if (widget.filled) {
        _ctl.forward(from: 0);
      } else {
        _ctl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          final scale = 1 + (_ctl.value * 0.18);
          return Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                widget.filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 44,
                color: widget.filled
                    ? BrandTokens.accentAmber
                    : BrandTokens.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TagSpec {
  final String label;
  final IconData icon;
  const _TagSpec(this.label, this.icon);
}

class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  const _TagChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? BrandTokens.primaryBlue
                : BrandTokens.bgSoft,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: selected
                  ? BrandTokens.primaryBlue
                  : BrandTokens.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : BrandTokens.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: BrandTypography.caption(
                  color: selected ? Colors.white : BrandTokens.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  const _SubmitButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandTokens.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: BrandTokens.primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Text(
                  'Submit rating',
                  style: BrandTypography.title(
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _ctl,
              curve: Curves.easeOutBack,
            ),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: BrandTokens.successGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: BrandTokens.successGreen,
                    blurRadius: 18,
                    spreadRadius: -6,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Thanks for your feedback!',
            style: BrandTypography.title(weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Your rating helps the next traveler choose the right helper.',
            textAlign: TextAlign.center,
            style: BrandTypography.caption(),
          ),
        ],
      ),
    );
  }
}