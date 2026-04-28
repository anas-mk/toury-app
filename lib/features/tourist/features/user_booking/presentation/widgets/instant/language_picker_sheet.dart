import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';

/// One language option presented in the language picker.
///
/// `code` is the wire value sent to the backend (ISO 639-1).
/// `name` is the friendly label shown in the UI.
class LanguageOption {
  final String? code;
  final String name;
  final String emoji;
  const LanguageOption({required this.code, required this.name, required this.emoji});
}

// IMPORTANT: emoji literals are written as Unicode escape sequences so
// they survive any UTF-16 / UTF-8 round-tripping. The previous source
// file contained mojibake like 'ðŸŒ' which the font fell back to as
// "öY" on screen. The escapes always decode to the right code points.
//   \u{1F310}                  = globe
//   \u{1F1XX}\u{1F1YY} pairs  = regional indicator flags
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
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
    ),
    builder: (ctx) => _LanguagePickerSheet(initialCode: initialCode),
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  final String? initialCode;
  const _LanguagePickerSheet({this.initialCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Preferred language',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                itemCount: kBookingLanguageOptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spaceXS),
                itemBuilder: (_, i) {
                  final option = kBookingLanguageOptions[i];
                  final selected = option.code == initialCode;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(option),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMD,
                        vertical: AppTheme.spaceMD,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : AppColor.lightBorder,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(option.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: AppTheme.spaceMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(option.name, style: theme.textTheme.bodyLarge),
                                if (option.code != null)
                                  Text(
                                    option.code!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColor.lightTextSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
          ],
        ),
      ),
    );
  }
}
