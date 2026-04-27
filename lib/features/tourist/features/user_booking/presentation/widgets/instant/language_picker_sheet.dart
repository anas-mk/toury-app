import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';

/// One language option presented in the language picker.
///
/// `code` is the wire value sent to the backend (ISO 639-1).
/// `name` is the friendly label shown in the UI.
class LanguageOption {
  final String? code; // null means "Any language"
  final String name;
  final String emoji;
  const LanguageOption({required this.code, required this.name, required this.emoji});
}

const List<LanguageOption> kBookingLanguageOptions = [
  LanguageOption(code: null, name: 'Any language', emoji: 'ðŸŒ'),
  LanguageOption(code: 'en', name: 'English', emoji: 'ðŸ‡¬ðŸ‡§'),
  LanguageOption(code: 'ar', name: 'Arabic', emoji: 'ðŸ‡ªðŸ‡¬'),
  LanguageOption(code: 'fr', name: 'French', emoji: 'ðŸ‡«ðŸ‡·'),
  LanguageOption(code: 'es', name: 'Spanish', emoji: 'ðŸ‡ªðŸ‡¸'),
  LanguageOption(code: 'de', name: 'German', emoji: 'ðŸ‡©ðŸ‡ª'),
  LanguageOption(code: 'it', name: 'Italian', emoji: 'ðŸ‡®ðŸ‡¹'),
  LanguageOption(code: 'ru', name: 'Russian', emoji: 'ðŸ‡·ðŸ‡º'),
  LanguageOption(code: 'zh', name: 'Chinese', emoji: 'ðŸ‡¨ðŸ‡³'),
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
