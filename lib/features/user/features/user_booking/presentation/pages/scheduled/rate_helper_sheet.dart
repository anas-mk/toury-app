import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../../user_ratings/domain/usecases/get_booking_rating_state_usecase.dart'
    as user_rat;
import '../../../../user_ratings/domain/usecases/rate_helper_usecase.dart'
    as user_rat;

/// Rating bottom-sheet shown after a trip completes (Fix 8).
///
/// Behaviour:
///   1. On open, queries `GET /ratings/booking/{bookingId}` so we can show
///      the "already rated" state when the user has already submitted
///      from another device or the mandatory rating overlay.
///   2. Stars are required (1..5). Comment is optional (max 500 chars).
///   3. POSTs to `/ratings/booking/{bookingId}/helper` via the existing
///      `RateHelperUseCase`. On success the sheet pops with `true` so
///      the caller can flip the CTA to "✓ Rated".
///
/// Reuses [user_rat.RateHelperUseCase] from the user_ratings feature
/// (Reuse > Create) instead of duplicating the request shape.
class RateHelperSheet extends StatefulWidget {
  final String bookingId;

  const RateHelperSheet({super.key, required this.bookingId});

  @override
  State<RateHelperSheet> createState() => _RateHelperSheetState();
}

class _RateHelperSheetState extends State<RateHelperSheet> {
  static const int _commentMax = 500;

  int _stars = 0;
  late final TextEditingController _commentCtrl;

  bool _loadingState = true;
  bool _alreadyRated = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
    _loadExistingState();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingState() async {
    try {
      final uc = sl<user_rat.GetBookingRatingStateUseCase>();
      final result = await uc(widget.bookingId);
      if (!mounted) return;
      result.fold(
        (failure) {
          // Endpoint missing or 404 → assume not yet rated. Don't surface
          // the error since this is a non-blocking optimistic check.
          setState(() {
            _loadingState = false;
            _alreadyRated = false;
          });
        },
        (data) {
          // The API returns a flag we can't strictly type from here, so
          // tolerate `userRated`, `hasUserRated`, `userHasRated`,
          // `userRating` (truthy means submitted).
          final flag = data['userRated'] ??
              data['hasUserRated'] ??
              data['userHasRated'] ??
              data['userRating'];
          final rated = flag == true ||
              (flag is int && flag > 0) ||
              (flag is Map && flag.isNotEmpty);
          setState(() {
            _loadingState = false;
            _alreadyRated = rated;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingState = false;
        _alreadyRated = false;
      });
    }
  }

  bool get _canSubmit => _stars >= 1 && _stars <= 5 && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    HapticFeedback.lightImpact();
    setState(() {
      _submitting = true;
      _error = null;
    });
    final uc = sl<user_rat.RateHelperUseCase>();
    final result = await uc(user_rat.RateHelperParams(
      bookingId: widget.bookingId,
      stars: _stars,
      comment: _commentCtrl.text.trim(),
      tags: const <String>[],
    ));
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
      },
      (_) {
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingState) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: BrandTokens.primaryBlue,
          ),
        ),
      );
    }

    if (_alreadyRated) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Already rated \u2713',
            style: BrandTypography.headline(),
          ),
          const SizedBox(height: 8),
          Text(
            'You\u2019ve already rated this helper. Thanks for the feedback!',
            style: BrandTypography.body(color: BrandTokens.textSecondary),
          ),
          const SizedBox(height: 16),
          GhostButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate your helper',
          style: BrandTypography.headline(),
        ),
        const SizedBox(height: 4),
        Text(
          'Your honest feedback helps us match you better next time.',
          style: BrandTypography.body(color: BrandTokens.textSecondary),
        ),
        const SizedBox(height: 16),
        Center(
          child: _StarRow(
            value: _stars,
            onChanged: (v) => setState(() => _stars = v),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentCtrl,
          maxLines: 4,
          maxLength: _commentMax,
          decoration: InputDecoration(
            hintText: 'Share what stood out (optional)',
            hintStyle: BrandTypography.body(color: BrandTokens.textMuted),
            filled: true,
            fillColor: BrandTokens.surfaceWhite,
            contentPadding: const EdgeInsets.all(14),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: BrandTokens.borderSoft),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: BrandTokens.borderSoft),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: BrandTokens.primaryBlue,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: BrandTypography.caption(color: BrandTokens.dangerRed),
          ),
        ],
        const SizedBox(height: 12),
        PrimaryGradientButton(
          label: _submitting ? 'Submitting\u2026' : 'Submit rating',
          icon: Icons.check_rounded,
          onPressed: _canSubmit ? _submit : null,
          visualEnabled: _canSubmit,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StarRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i < value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(i + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              active ? Icons.star_rounded : Icons.star_border_rounded,
              size: 38,
              color: active
                  ? const Color(0xFFF59E0B)
                  : BrandTokens.textMuted,
            ),
          ),
        );
      }),
    );
  }
}
