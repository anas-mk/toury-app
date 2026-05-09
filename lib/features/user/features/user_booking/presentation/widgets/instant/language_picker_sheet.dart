import 'package:flutter/material.dart';

import '../../../../../../../core/theme/brand_tokens.dart';

/// One language option presented in the language picker.
///
/// `code` is the wire value sent to the backend (ISO 639-1).
/// `name` is the friendly label shown in the UI.
class LanguageOption {
  final String? code;
  final String name;
  final String emoji;
  const LanguageOption(
      {required this.code, required this.name, required this.emoji});
}

// IMPORTANT: emoji literals are written as Unicode escape sequences so
// they survive any UTF-16 / UTF-8 round-tripping.
const List<LanguageOption> kBookingLanguageOptions = [
  LanguageOption(code: null, name: 'Any language', emoji: '\u{1F310}'),
  LanguageOption(code: 'en', name: 'English', emoji: '\u{1F1EC}\u{1F1E7}'),
  LanguageOption(code: 'ar', name: 'Arabic', emoji: '\u{1F1EA}\u{1F1EC}'),
  LanguageOption(code: 'fr', name: 'French', emoji: '\u{1F1EB}\u{1F1F7}'),
  LanguageOption(code: 'es', name: 'Spanish', emoji: '\u{1F1EA}\u{1F1F8}'),
  LanguageOption(code: 'de', name: 'German', emoji: '\u{1F1E9}\u{1F1EA}'),
  LanguageOption(code: 'it', name: 'Italian', emoji: '\u{1F1EE}\u{1F1F9}'),
  LanguageOption(code: 'ru', name: 'Russian', emoji: '\u{1F1F7}\u{1F1FA}'),
  LanguageOption(code: 'zh', name: 'Chinese', emoji: '\u{1F1E8}\u{1F1F3}'),
];

LanguageOption languageOptionForCode(String? code) {
  for (final o in kBookingLanguageOptions) {
    if (o.code == code) return o;
  }
  return kBookingLanguageOptions.first;
}

Future<LanguageOption?> showLanguagePickerSheet(
  BuildContext context, {
  String? initialCode,
}) {
  return showModalBottomSheet<LanguageOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LanguagePickerSheet(initialCode: initialCode),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _LanguagePickerSheet extends StatefulWidget {
  final String? initialCode;
  const _LanguagePickerSheet({this.initialCode});

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LanguageOption> get _anyOptions => kBookingLanguageOptions
      .where((o) => o.code == null)
      .where(_matches)
      .toList();

  List<LanguageOption> get _langOptions => kBookingLanguageOptions
      .where((o) => o.code != null)
      .where(_matches)
      .toList();

  bool _matches(LanguageOption o) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return o.name.toLowerCase().contains(q) ||
        (o.code?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final anyOpts = _anyOptions;
    final langOpts = _langOptions;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF767683).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Language',
                    style: BrandTokens.heading(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.primaryBlue,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: BrandTokens.bgSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Container(
              decoration: BoxDecoration(
                color: BrandTokens.bgSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BrandTokens.borderSoft),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: BrandTokens.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: BrandTokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search language…',
                  hintStyle:
                      BrandTokens.body(fontSize: 14, color: BrandTokens.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: BrandTokens.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Any language" – full-width hero card
                  if (anyOpts.isNotEmpty) ...[
                    _AnyLanguageCard(
                      option: anyOpts.first,
                      selected: widget.initialCode == null,
                      onTap: () => Navigator.pop(context, anyOpts.first),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Section header
                  if (langOpts.isNotEmpty) ...[
                    Text(
                      'LANGUAGES',
                      style: BrandTokens.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BrandTokens.textSecondary,
                      ).copyWith(letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 12),
                    // 3-column flag grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: langOpts.length,
                      itemBuilder: (_, i) {
                        final opt = langOpts[i];
                        return _LanguageCard(
                          option: opt,
                          selected: opt.code == widget.initialCode,
                          onTap: () => Navigator.pop(context, opt),
                        );
                      },
                    ),
                  ],
                  // Empty state
                  if (anyOpts.isEmpty && langOpts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No language found',
                          style: BrandTokens.body(color: BrandTokens.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Any language – full-width card ──────────────────────────────────────────

class _AnyLanguageCard extends StatelessWidget {
  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;
  const _AnyLanguageCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? BrandTokens.primaryBlue
              : BrandTokens.bgSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? BrandTokens.primaryBlue
                : BrandTokens.borderSoft,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: BrandTokens.primaryBlue.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.name,
                    style: BrandTokens.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : BrandTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Match helpers regardless of language',
                    style: BrandTokens.body(
                      fontSize: 12,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.72)
                          : BrandTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22)
            else
              Icon(Icons.chevron_right_rounded,
                  color: BrandTokens.textSecondary.withValues(alpha: 0.40),
                  size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Individual language card (grid item) ────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? BrandTokens.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? BrandTokens.primaryBlue
                : BrandTokens.borderSoft,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: BrandTokens.primaryBlue.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: BrandTokens.shadowSoft,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Check badge top-right
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            // Card content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      option.name,
                      style: BrandTokens.heading(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : BrandTokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.code != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.20)
                              : BrandTokens.primaryBlue.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          option.code!.toUpperCase(),
                          style: BrandTokens.body(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : BrandTokens.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
