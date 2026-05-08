// Modern shared full-width action button used by booking flows.
//
// Replaces both the previous `_ActionBtn` (helper_booking_details_page.dart)
// and `_TripBtn` (active_booking_components.dart). For trip-action buttons
// that should reflect the [TripActionCubit] loading state, use
// [BookingActionButton.tripAction] which automatically wires the cubit and
// matches the button to a specific `actionType`.
//
// Variants:
//   • `BookingActionButton(...)`              – solid fill, soft glow.
//   • `BookingActionButton(outline: true)`    – ghost outline button.
//   • `BookingActionButton.tripAction(...)`   – binds to TripActionCubit.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/widgets/app_loading.dart';
import '../../cubit/trip_action_cubit.dart';

class BookingActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color color;
  final VoidCallback? onTap;
  final bool outline;
  final bool isLoading;
  final bool isDisabled;
  final double height;

  const BookingActionButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    required this.color,
    required this.onTap,
    this.outline = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = AppSize.buttonLg,
  });

  /// Variant that listens to [TripActionCubit] and shows a spinner whenever
  /// `state.actionType == [actionType]`.
  static Widget tripAction({
    Key? key,
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required Color color,
    required VoidCallback? onTap,
    required String actionType,
    bool outline = false,
    bool isDisabled = false,
    double height = AppSize.buttonLg,
  }) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final loading =
            state is TripActionLoading && state.actionType == actionType;
        return BookingActionButton(
          key: key,
          label: label,
          icon: icon,
          trailingIcon: trailingIcon,
          color: color,
          outline: outline,
          isLoading: loading,
          isDisabled: isDisabled,
          height: height,
          onTap: onTap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final disabled = isDisabled || isLoading || onTap == null;
    final contentColor = outline ? color : Colors.white;

    final Widget content = isLoading
        ? AppSpinner(size: 22, strokeWidth: 2.5, color: contentColor)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: contentColor, size: AppSize.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, color: contentColor, size: AppSize.iconMd),
              ],
            ],
          );

    if (outline) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: disabled ? palette.border : color.withValues(alpha: 0.65),
              width: AppSize.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: disabled ? null : onTap,
            child: Center(child: content),
          ),
        ),
      );
    }

    // Solid filled variant with soft brand glow.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    Color.lerp(color, Colors.black, 0.12)!,
                  ],
                ),
          color: disabled ? palette.disabledFill : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.34),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: disabled ? null : onTap,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
