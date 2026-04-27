import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_button.dart';

const int kMinDurationMinutes = 60;
const int kMaxDurationMinutes = 24 * 60;

const List<int> kDurationPresetMinutes = [60, 120, 180, 240, 360, 480];

String formatDurationMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Opens a bottom sheet with hours + minutes wheels and returns the new
/// duration in minutes (or `null` if the user cancels).
Future<int?> showCustomDurationSheet(
  BuildContext context, {
  required int initialMinutes,
}) {
  final initialClamped =
      initialMinutes.clamp(kMinDurationMinutes, kMaxDurationMinutes);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
    ),
    builder: (ctx) => _CustomDurationSheet(initialMinutes: initialClamped),
  );
}

class _CustomDurationSheet extends StatefulWidget {
  final int initialMinutes;
  const _CustomDurationSheet({required this.initialMinutes});

  @override
  State<_CustomDurationSheet> createState() => _CustomDurationSheetState();
}

class _CustomDurationSheetState extends State<_CustomDurationSheet> {
  late int _hours;
  late int _minutes;

  late final FixedExtentScrollController _hoursCtrl;
  late final FixedExtentScrollController _minutesCtrl;

  static const List<int> _hourOptions = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
  ];
  static const List<int> _minuteOptions = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    _hours = widget.initialMinutes ~/ 60;
    final remainder = widget.initialMinutes % 60;
    final closestMinute = _minuteOptions.reduce(
      (a, b) => (remainder - a).abs() <= (remainder - b).abs() ? a : b,
    );
    _minutes = closestMinute;

    _hoursCtrl = FixedExtentScrollController(
      initialItem: _hourOptions.indexOf(_hours.clamp(1, 24)),
    );
    _minutesCtrl = FixedExtentScrollController(
      initialItem: _minuteOptions.indexOf(_minutes),
    );
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  int get _totalMinutes => _hours * 60 + _minutes;

  bool get _isValid =>
      _totalMinutes >= kMinDurationMinutes &&
      _totalMinutes <= kMaxDurationMinutes;

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
            Text('Custom duration', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Select between 1 and 24 hours',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColor.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _Wheel(
                      controller: _hoursCtrl,
                      label: 'Hours',
                      values: _hourOptions,
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                  ),
                  Expanded(
                    child: _Wheel(
                      controller: _minutesCtrl,
                      label: 'Minutes',
                      values: _minuteOptions,
                      onChanged: (v) => setState(() => _minutes = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              child: Text(
                'Total: ${formatDurationMinutes(_totalMinutes)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
              child: CustomButton(
                text: 'Confirm',
                onPressed: _isValid
                    ? () => Navigator.of(context).pop(_totalMinutes)
                    : null,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<int> values;
  final String label;
  final ValueChanged<int> onChanged;

  const _Wheel({
    required this.controller,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColor.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 36,
            onSelectedItemChanged: (i) => onChanged(values[i]),
            children: [
              for (final v in values)
                Center(
                  child: Text(
                    v.toString().padLeft(2, '0'),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
