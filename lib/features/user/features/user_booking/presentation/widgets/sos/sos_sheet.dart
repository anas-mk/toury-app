import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';

enum SosReason {
  accident('Accident', 'Accident'),
  unsafeSituation('Unsafe situation', 'Unsafe'),
  medical('Medical', 'Medical'),
  other('Other', 'Other');

  const SosReason(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

class SosSheetResult {
  const SosSheetResult({required this.reason, this.note});

  final SosReason reason;
  final String? note;
}

typedef SosTriggerCallback = Future<String?> Function(SosSheetResult result);

Future<bool?> showSosSheet(
  BuildContext context, {
  required SosTriggerCallback onTrigger,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SosSheet(onTrigger: onTrigger),
  );
}

class SosSheet extends StatefulWidget {
  const SosSheet({super.key, required this.onTrigger});

  final SosTriggerCallback onTrigger;

  @override
  State<SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends State<SosSheet> {
  final TextEditingController _noteController = TextEditingController();
  SosReason _reason = SosReason.other;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _callEmergencyNumber() async {
    final uri = Uri(scheme: 'tel', path: '122');
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open phone dialer')),
    );
  }

  Future<void> _triggerSos() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final note = _noteController.text.trim();
    final error = await widget.onTrigger(
      SosSheetResult(
        reason: _reason,
        note: note.isEmpty ? null : note,
      ),
    );

    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            AppTheme.spaceLG,
            AppTheme.spaceLG,
            AppTheme.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColor.lightBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColor.errorColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      color: AppColor.errorColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need help?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Support will be alerted and your location will be shared with our safety team.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColor.lightTextSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLG),
              FilledButton.icon(
                onPressed: _submitting ? null : _callEmergencyNumber,
                icon: const Icon(Icons.phone_in_talk_rounded, size: 26),
                label: const Text('Call 122'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: AppColor.errorColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                'Reason',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final reason in SosReason.values)
                    ChoiceChip(
                      label: Text(reason.label),
                      selected: _reason == reason,
                      onSelected: _submitting
                          ? null
                          : (_) => setState(() => _reason = reason),
                      selectedColor: AppColor.errorColor.withValues(alpha: 0.16),
                      checkmarkColor: AppColor.errorColor,
                      labelStyle: TextStyle(
                        color: _reason == reason
                            ? AppColor.errorColor
                            : AppColor.lightTextSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(
                        color: _reason == reason
                            ? AppColor.errorColor
                            : AppColor.lightBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLG),
              TextField(
                controller: _noteController,
                enabled: !_submitting,
                maxLines: 4,
                maxLength: 1000,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Anything that helps the safety team (optional)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppColor.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              FilledButton(
                onPressed: _submitting ? null : _triggerSos,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColor.errorColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Trigger SOS'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColor.lightTextSecondary,
                  side: const BorderSide(color: AppColor.lightBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}