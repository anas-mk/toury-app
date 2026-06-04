import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/brand_tokens.dart';

/// Shared rating-form body — the stars row, "what stood out?" chips,
/// and the free-text area. Used by both the full-screen
/// `RateBookingPage` and the dialog inside `MandatoryRatingOverlay`
/// so the two surfaces stay visually identical.
///
/// The form is uncontrolled: the parent owns the "is the user
/// allowed to submit?" gate via [onStarsChanged] and pulls the
/// current `comment` / `selectedTags` off [GlobalKey<RatingFormState>]
/// when it's time to fire the submit use case.
class RatingForm extends StatefulWidget {
  /// Notified whenever the star count changes. The parent uses this
  /// to enable/disable its Submit button.
  final ValueChanged<int>? onStarsChanged;

  /// Whether inputs are disabled (e.g. while submitting).
  final bool disabled;

  /// Initial state — useful when the parent restores from a draft.
  final int initialStars;
  final List<String> initialTags;
  final String initialComment;

  /// Compact mode shrinks the stars + chip sizes a touch so the form
  /// fits comfortably inside a `Dialog`.
  final bool compact;

  const RatingForm({
    super.key,
    this.onStarsChanged,
    this.disabled = false,
    this.initialStars = 0,
    this.initialTags = const [],
    this.initialComment = '',
    this.compact = false,
  });

  @override
  State<RatingForm> createState() => RatingFormState();
}

class RatingFormState extends State<RatingForm> {
  late int _stars = widget.initialStars;
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialComment);
  late final List<String> _selectedTags = List<String>.from(widget.initialTags);

  static const List<String> _availableTags = [
    'Friendly',
    'Professional',
    'Knowledgeable',
    'Punctual',
    'Great Tips',
  ];

  int get stars => _stars;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);
  String get comment => _ctrl.text;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setStars(int value) {
    if (widget.disabled) return;
    HapticFeedback.selectionClick();
    setState(() => _stars = value);
    widget.onStarsChanged?.call(value);
  }

  void _toggleTag(String tag) {
    if (widget.disabled) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final starSize = widget.compact ? 42.0 : 52.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _stars;
            return _StarTap(
              filled: filled,
              size: starSize,
              onTap: () => _setStars(i + 1),
            );
          }),
        ),
        SizedBox(height: widget.compact ? 20 : 32),
        const Text(
          'WHAT STOOD OUT?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: Color(0xFF464652),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _availableTags.map((t) {
            final selected = _selectedTags.contains(t);
            return _TagChip(
              label: t,
              selected: selected,
              compact: widget.compact,
              onTap: () => _toggleTag(t),
            );
          }).toList(),
        ),
        SizedBox(height: widget.compact ? 18 : 24),
        _CommentField(
          controller: _ctrl,
          enabled: !widget.disabled,
          compact: widget.compact,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star — fills with the brand amber when active + soft glow.
// ─────────────────────────────────────────────────────────────────────────────

class _StarTap extends StatelessWidget {
  final bool filled;
  final double size;
  final VoidCallback onTap;
  const _StarTap({
    required this.filled,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: filled ? 1.1 : 1.0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              key: ValueKey<bool>(filled),
              size: size,
              color: filled
                  ? const Color(0xFFFE9331)
                  : const Color(0xFFC6C5D4),
              shadows: filled
                  ? const [
                      Shadow(
                        color: Color(0x66FE9331),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip — pill toggle for tags. Matches the html mock's chip styling.
// ─────────────────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const _TagChip({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 14.0 : 18.0;
    final vPad = compact ? 8.0 : 10.0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color:
                selected ? BrandTokens.primaryBlue : const Color(0xFFFBF8FF),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? BrandTokens.primaryBlue
                  : const Color(0x80C6C5D4),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: BrandTokens.primaryBlue.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF464652),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment field — soft surface, primary outline on focus.
// ─────────────────────────────────────────────────────────────────────────────

class _CommentField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool compact;
  const _CommentField({
    required this.controller,
    required this.enabled,
    required this.compact,
  });

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.compact ? 3 : 4;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _focused ? Colors.white : const Color(0xFFFAF8F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _focused
              ? BrandTokens.primaryBlue.withValues(alpha: 0.5)
              : const Color(0x66C6C5D4),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        enabled: widget.enabled,
        maxLines: lines,
        minLines: lines,
        maxLength: 240,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1B1B21),
          height: 1.5,
        ),
        decoration: InputDecoration(
          isDense: false,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          hintText: 'Share details of your own experience...',
          hintStyle: TextStyle(
            color: const Color(0xFF464652).withValues(alpha: 0.45),
            fontSize: 15,
          ),
          counterStyle: TextStyle(
            color: const Color(0xFF464652).withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
