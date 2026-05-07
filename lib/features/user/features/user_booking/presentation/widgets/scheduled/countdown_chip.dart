import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';

/// Phase 5 \u2014 inline countdown chip used for time-sensitive moments
/// (response deadline, trip start time, etc.).
///
/// Updates once per second. Once the deadline has passed, switches into
/// the "expired" tone and stops the timer. The widget never schedules
/// network work; the parent screen is responsible for refetching state
/// after expiry if it cares about the new server-side status.
class CountdownChip extends StatefulWidget {
  /// Target moment to count down to.
  final DateTime deadline;

  /// Prefix shown before the live duration (e.g. "Helper replies in").
  final String label;

  /// Label shown once the deadline has passed.
  final String expiredLabel;

  /// Optional icon. Defaults to a clock.
  final IconData icon;

  /// Render as a smaller chip suitable for inline placement.
  final bool dense;

  const CountdownChip({
    super.key,
    required this.deadline,
    this.label = 'Replies in',
    this.expiredLabel = 'Time\u2019s up',
    this.icon = Icons.timer_rounded,
    this.dense = false,
  });

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  Timer? _ticker;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  @override
  void didUpdateWidget(covariant CountdownChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _recompute();
    }
  }

  void _recompute() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _remaining = widget.deadline.difference(now);
      if (_remaining.isNegative) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.isNegative || _remaining.inSeconds <= 0;
    final palette = _palette(expired);

    final hPad = widget.dense ? 10.0 : 12.0;
    final vPad = widget.dense ? 6.0 : 8.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: widget.dense ? 14 : 16, color: palette.fg),
          const SizedBox(width: 6),
          Text(
            expired
                ? widget.expiredLabel
                : '${widget.label} ${_format(_remaining)}',
            style: BrandTypography.caption(
              color: palette.fg,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final total = d.inSeconds;
    if (total >= 3600) {
      final h = (total ~/ 3600).toString();
      final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
      return '${h}h ${m}m';
    }
    if (total >= 60) {
      final m = (total ~/ 60).toString();
      final s = (total % 60).toString().padLeft(2, '0');
      return '${m}:$s';
    }
    return '${total}s';
  }

  ({Color fg, Color bg, Color border}) _palette(bool expired) {
    if (expired) {
      return (
        fg: BrandTokens.dangerRed,
        bg: BrandTokens.dangerRedSoft,
        border: BrandTokens.dangerRed,
      );
    }
    if (_remaining.inSeconds <= 60) {
      return (
        fg: BrandTokens.dangerRed,
        bg: BrandTokens.dangerRedSoft,
        border: BrandTokens.dangerRedSoft,
      );
    }
    if (_remaining.inMinutes <= 5) {
      return (
        fg: BrandTokens.accentAmberText,
        bg: BrandTokens.accentAmberSoft,
        border: BrandTokens.accentAmberBorder,
      );
    }
    return (
      fg: BrandTokens.primaryBlue,
      bg: BrandTokens.borderTinted,
      border: BrandTokens.borderTinted,
    );
  }
}
