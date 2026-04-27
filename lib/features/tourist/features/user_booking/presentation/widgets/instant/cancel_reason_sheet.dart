import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_button.dart';

const List<String> kInstantCancelReasons = [
  'Plans changed',
  'Found another option',
  'Helper too far',
  'Other',
];

/// Bottom-sheet picker for a cancel reason. Returns the chosen reason or
/// `null` if the user dismisses the sheet.
Future<String?> showCancelReasonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
    ),
    builder: (_) => const _CancelReasonSheet(),
  );
}

class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet();

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  String? _selected;
  final TextEditingController _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  String? _resolvedReason() {
    if (_selected == null) return null;
    if (_selected == 'Other') {
      final text = _otherCtrl.text.trim();
      if (text.length < 5) return null;
      return text;
    }
    return _selected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
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
              Text('Why are you cancelling?', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppTheme.spaceLG),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                child: Column(
                  children: [
                    for (final r in kInstantCancelReasons) _buildRadioTile(r),
                    if (_selected == 'Other') ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      TextField(
                        controller: _otherCtrl,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 1000,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Please tell us more (5–1000 chars)',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceMD),
                    CustomButton(
                      text: 'Cancel request',
                      variant: ButtonVariant.danger,
                      onPressed: _resolvedReason() == null
                          ? null
                          : () =>
                              Navigator.of(context).pop(_resolvedReason()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String reason) {
    return RadioListTile<String>(
      value: reason,
      groupValue: _selected,
      title: Text(reason),
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _selected = v),
    );
  }
}
