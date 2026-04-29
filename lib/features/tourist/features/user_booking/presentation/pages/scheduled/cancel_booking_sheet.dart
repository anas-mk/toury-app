import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../cubits/cancel_booking_cubit.dart';

/// Result returned via [Navigator.pop] when the cancel action succeeds.
class CancelResult {
  final String reason;
  const CancelResult(this.reason);
}

/// Bottom sheet that confirms a cancellation and asks for a reason.
///
/// Shows penalty / refund honesty (per the brief\u2019s "Cancellation
/// honesty" principle): the user sees the consequences before confirming.
///
/// Reuses [CancelBookingCubit] so the API contract stays single-sourced
/// with the rest of the cancel flows.
class CancelBookingSheet extends StatelessWidget {
  final String bookingId;

  /// Optional context hint shown above the reason field, e.g. "before
  /// trip start", "after helper accepted", etc. Pure presentation.
  final String? contextHint;

  /// Optional preview of the refund the user can expect. Backend stays
  /// the source of truth — this is just an honest preview.
  final String? refundHint;

  /// True when, based on the booking detail, this cancellation is
  /// expected to forfeit the deposit (Fix 9). Drives the warning chrome
  /// (red border, alert icon) on the refund row.
  final bool forfeitsDeposit;

  const CancelBookingSheet({
    super.key,
    required this.bookingId,
    this.contextHint,
    this.refundHint,
    this.forfeitsDeposit = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CancelBookingCubit>(
      create: (_) => sl<CancelBookingCubit>(),
      child: _CancelBody(
        bookingId: bookingId,
        contextHint: contextHint,
        refundHint: refundHint,
        forfeitsDeposit: forfeitsDeposit,
      ),
    );
  }
}

class _CancelBody extends StatefulWidget {
  final String bookingId;
  final String? contextHint;
  final String? refundHint;
  final bool forfeitsDeposit;

  const _CancelBody({
    required this.bookingId,
    this.contextHint,
    this.refundHint,
    this.forfeitsDeposit = false,
  });

  @override
  State<_CancelBody> createState() => _CancelBodyState();
}

class _CancelBodyState extends State<_CancelBody> {
  late final TextEditingController _reasonCtrl;
  String? _selectedPreset;

  static const _presets = <String>[
    'Plans changed',
    'Booked by mistake',
    'Found another helper',
    'Helper not responding',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String? get _resolvedReason {
    final text = _reasonCtrl.text.trim();
    if (text.isNotEmpty) return text;
    if (_selectedPreset != null && _selectedPreset != 'Other') {
      return _selectedPreset;
    }
    return null;
  }

  void _confirm(BuildContext context) {
    final reason = _resolvedReason;
    if (reason == null) return;
    HapticFeedback.lightImpact();
    context.read<CancelBookingCubit>().cancel(widget.bookingId, reason);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CancelBookingCubit, CancelBookingState>(
      listener: (context, state) {
        if (state is CancelBookingSuccess) {
          Navigator.of(context)
              .pop(CancelResult(_resolvedReason ?? 'Cancelled'));
        } else if (state is CancelBookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: BrandTokens.dangerRed,
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BrandTokens.dangerRedSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: BrandTokens.dangerRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cancel this booking?',
                  style: BrandTypography.headline(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.contextHint != null)
            _Notice(
              icon: Icons.info_outline_rounded,
              text: widget.contextHint!,
            ),
          if (widget.refundHint != null) ...[
            const SizedBox(height: 8),
            _Notice(
              icon: widget.forfeitsDeposit
                  ? Icons.warning_amber_rounded
                  : Icons.account_balance_wallet_rounded,
              text: widget.refundHint!,
              // Forfeit warnings are red so the user can't miss them
              // (Fix 9). Refundable / free wording stays amber.
              tone: widget.forfeitsDeposit
                  ? _NoticeTone.danger
                  : _NoticeTone.amber,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Why are you cancelling?',
            style: BrandTypography.body(weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map(
                  (preset) => GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedPreset = preset;
                        if (preset != 'Other') _reasonCtrl.clear();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedPreset == preset
                            ? BrandTokens.primaryBlue
                            : BrandTokens.surfaceWhite,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: _selectedPreset == preset
                              ? BrandTokens.primaryBlue
                              : BrandTokens.borderSoft,
                        ),
                      ),
                      child: Text(
                        preset,
                        style: BrandTypography.caption(
                          color: _selectedPreset == preset
                              ? Colors.white
                              : BrandTokens.textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (_selectedPreset == 'Other') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              maxLength: 240,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tell us briefly\u2026',
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
          ],
          const SizedBox(height: 18),
          BlocBuilder<CancelBookingCubit, CancelBookingState>(
            builder: (context, state) {
              final loading = state is CancelBookingLoading;
              return Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Keep booking',
                      icon: Icons.arrow_back_rounded,
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DangerButton(
                      label: loading ? 'Cancelling\u2026' : 'Yes, cancel',
                      enabled: !loading && _resolvedReason != null,
                      onPressed: () => _confirm(context),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

enum _NoticeTone { neutral, amber, danger }

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final _NoticeTone tone;

  const _Notice({
    required this.icon,
    required this.text,
    this.tone = _NoticeTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color iconColor;
    switch (tone) {
      case _NoticeTone.amber:
        bg = BrandTokens.accentAmberSoft;
        border = BrandTokens.accentAmberBorder;
        iconColor = BrandTokens.accentAmberText;
        break;
      case _NoticeTone.danger:
        bg = BrandTokens.dangerRedSoft;
        border = BrandTokens.dangerRed;
        iconColor = BrandTokens.dangerRed;
        break;
      case _NoticeTone.neutral:
        bg = BrandTokens.bgSoft;
        border = BrandTokens.borderSoft;
        iconColor = BrandTokens.textSecondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: BrandTypography.caption(color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _DangerButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: BrandTokens.dangerRed,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                label,
                style: BrandTypography.body(
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
