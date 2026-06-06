import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/brand_tokens.dart';

class StaticAppLanguageOption {
  final String code;
  final String label;
  final String emoji;

  const StaticAppLanguageOption({
    required this.code,
    required this.label,
    required this.emoji,
  });
}

const List<StaticAppLanguageOption> kStaticAppLanguages = [
  StaticAppLanguageOption(
    code: 'en',
    label: 'English (US)',
    emoji: '\u{1F1FA}\u{1F1F8}',
  ),
  StaticAppLanguageOption(
    code: 'ar',
    label: 'Arabic',
    emoji: '\u{1F1EA}\u{1F1EC}',
  ),
  StaticAppLanguageOption(
    code: 'fr',
    label: 'French',
    emoji: '\u{1F1EB}\u{1F1F7}',
  ),
  StaticAppLanguageOption(
    code: 'es',
    label: 'Spanish',
    emoji: '\u{1F1EA}\u{1F1F8}',
  ),
  StaticAppLanguageOption(
    code: 'de',
    label: 'German',
    emoji: '\u{1F1E9}\u{1F1EA}',
  ),
];

StaticAppLanguageOption staticAppLanguageForCode(String code) {
  for (final option in kStaticAppLanguages) {
    if (option.code == code) return option;
  }
  return kStaticAppLanguages.first;
}

Future<StaticAppLanguageOption?> showStaticAppLanguagePicker(
  BuildContext context, {
  required String selectedCode,
}) {
  return showModalBottomSheet<StaticAppLanguageOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StaticAppLanguageSheet(selectedCode: selectedCode),
  );
}

class _StaticAppLanguageSheet extends StatelessWidget {
  final String selectedCode;

  const _StaticAppLanguageSheet({required this.selectedCode});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'App Language',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad + 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...kStaticAppLanguages.map((option) {
                        final selected = option.code == selectedCode;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context, option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? BrandTokens.primaryBlue
                                          .withValues(alpha: 0.08)
                                      : palette.surfaceInset,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? BrandTokens.primaryBlue
                                            .withValues(alpha: 0.35)
                                        : palette.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      option.emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style:
                                            theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: BrandTokens.primaryBlue,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
