import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/brand_tokens.dart';

enum HelperSosReason {
  accident('Accident', 'Accident'),
  unsafeSituation('Unsafe situation', 'Unsafe'),
  medical('Medical', 'Medical'),
  clientAggressive('Aggressive client', 'AggressiveClient'),
  other('Other', 'Other');

  const HelperSosReason(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

class HelperSosSheetResult {
  const HelperSosSheetResult({required this.reason, this.note});

  final HelperSosReason reason;
  final String? note;
}

typedef HelperSosTriggerCallback = Future<String?> Function(HelperSosSheetResult result);

Future<bool?> showHelperSosSheet(
  BuildContext context, {
  required HelperSosTriggerCallback onTrigger,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => HelperSosSheet(onTrigger: onTrigger),
  );
}

class HelperSosSheet extends StatefulWidget {
  const HelperSosSheet({super.key, required this.onTrigger});

  final HelperSosTriggerCallback onTrigger;

  @override
  State<HelperSosSheet> createState() => _HelperSosSheetState();
}

class _HelperSosSheetState extends State<HelperSosSheet> {
  final TextEditingController _noteController = TextEditingController();
  HelperSosReason _reason = HelperSosReason.other;
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
      HelperSosSheetResult(
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: BrandTokens.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: BrandTokens.borderSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: BrandTokens.dangerRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      color: BrandTokens.dangerRed,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need help?',
                          style: BrandTokens.heading(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Support will be alerted and your location will be shared with our safety team.',
                          style: BrandTokens.body(
                            color: BrandTokens.textSecondary,
                            fontSize: 14,
                          ).copyWith(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _callEmergencyNumber,
                icon: const Icon(Icons.phone_in_talk_rounded, size: 26),
                label: const Text('Call 122'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: BrandTokens.dangerRed,
                  foregroundColor: BrandTokens.surfaceWhite,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reason',
                style: BrandTokens.heading(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final reason in HelperSosReason.values)
                    ChoiceChip(
                      label: Text(reason.label),
                      selected: _reason == reason,
                      onSelected: _submitting
                          ? null
                          : (_) => setState(() => _reason = reason),
                      selectedColor: BrandTokens.dangerRed.withValues(alpha: 0.16),
                      checkmarkColor: BrandTokens.dangerRed,
                      labelStyle: TextStyle(
                        color: _reason == reason
                            ? BrandTokens.dangerRed
                            : BrandTokens.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(
                        color: _reason == reason
                            ? BrandTokens.dangerRed
                            : BrandTokens.borderSoft,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
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
                  fillColor: BrandTokens.bgSoft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _triggerSos,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: BrandTokens.dangerRed,
                  foregroundColor: BrandTokens.surfaceWhite,
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
                          color: BrandTokens.surfaceWhite,
                        ),
                      )
                    : const Text('Trigger SOS'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: BrandTokens.textSecondary,
                  side: const BorderSide(color: BrandTokens.borderSoft),
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
