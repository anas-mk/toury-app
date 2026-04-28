import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/widgets/custom_button.dart';

const List<String> kInstantCancelReasons = [
  'Plans changed',
  'Found another option',
  'Helper too far',
  'Other',
];

/// Bottom-sheet picker for a cancel reason. Returns the chosen reason or
/// `null` if the user dismisses the sheet.
Future<String?> showCancelReasonSheet(
  BuildContext context, {
  bool refundToWallet = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXL),
      ),
    ),
    builder: (_) => _CancelReasonSheet(refundToWallet: refundToWallet),
  );
}

class _CancelReasonSheet extends StatefulWidget {
  final bool refundToWallet;

  const _CancelReasonSheet({required this.refundToWallet});

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
              Text(
                'Why are you cancelling?',
                style: theme.textTheme.headlineSmall,
              ),
              if (widget.refundToWallet) ...[
                const SizedBox(height: AppTheme.spaceMD),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLG,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: BrandTokens.accentAmber.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(
                        color: BrandTokens.accentAmber.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: BrandTokens.accentAmberText,
                        ),
                        const SizedBox(width: AppTheme.spaceSM),
                        Expanded(
                          child: Text(
                            'Card payment will be refunded to your wallet once wallet refunds are enabled.',
                            style: BrandTokens.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: BrandTokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceLG),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                ),
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
                          : () => Navigator.of(context).pop(_resolvedReason()),
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
    final selected = _selected == reason;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      onTap: () => setState(() => _selected = reason),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : AppColor.lightBorder,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(child: Text(reason)),
          ],
        ),
      ),
    );
  }
}
