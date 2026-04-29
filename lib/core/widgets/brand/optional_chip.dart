import 'package:flutter/material.dart';

import '../../theme/brand_tokens.dart';

/// Small badge that flags a form field as optional.
///
/// Renders a soft amber capsule with the label "Optional" and an optional
/// helper line directly underneath. Use it next to the field label so the
/// user instantly understands the field can be skipped without breaking
/// anything.
///
/// ```dart
/// Row(children: [
///   const Text('Pickup location'),
///   const SizedBox(width: 8),
///   const OptionalChip(),
/// ]),
/// const OptionalHint(text: 'Add pickup to get an accurate price.'),
/// ```
class OptionalChip extends StatelessWidget {
  /// Override the displayed text. Defaults to "Optional".
  final String label;

  /// Compact mode for inline placement next to a single-line label.
  final bool compact;

  const OptionalChip({super.key, this.label = 'Optional', this.compact = false});

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 8.0 : 10.0;
    final vPad = compact ? 2.0 : 3.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: BrandTokens.accentAmberSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BrandTokens.accentAmberBorder, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          color: BrandTokens.accentAmberText,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// One-line helper text that explains WHEN to provide an optional field.
///
/// Pair every [OptionalChip] with this widget right below the input row so
/// the optionality message is visible without requiring a tooltip tap.
class OptionalHint extends StatelessWidget {
  final String text;
  final IconData icon;

  const OptionalHint({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: BrandTokens.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: BrandTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
