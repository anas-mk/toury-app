import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/brand_tokens.dart';

// Tap-state mixin: scale to 0.96 on press, spring back.
abstract class _PressableState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 240),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (down) {
      _ctl.forward();
    } else {
      _ctl.reverse();
    }
  }

  Widget pressable({required Widget child, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _press(true) : null,
      onTapCancel: enabled ? () => _press(false) : null,
      onTapUp: enabled ? (_) => _press(false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: ScaleTransition(scale: _scale, child: child),
    );
  }
}

// Primary CTA: blue gradient + colored blue glow shadow.
class PrimaryGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool visualEnabled;
  final double height;

  const PrimaryGradientButton({
    super.key,
    required this.label,
    this.icon,
    this.isLoading = false,
    required this.onPressed,
    this.visualEnabled = true,
    this.height = 60,
  });

  @override
  State<PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends _PressableState<PrimaryGradientButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final muted = enabled && !widget.visualEnabled;
    final opacity = widget.isLoading ? 1.0 : (muted ? 0.55 : 1.0);

    final body = Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: BrandTokens.primaryGradient,
        boxShadow: enabled && widget.visualEnabled
            ? BrandTokens.ctaBlueGlow
            : null,
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: BrandTokens.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );

    return Opacity(
      opacity: opacity,
      child: pressable(
        onTap: enabled ? widget.onPressed : null,
        child: body,
      ),
    );
  }
}

// Amber pill CTA — used for the Instant action.
class AmberPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  const AmberPillButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.height = 60,
  });

  @override
  State<AmberPillButton> createState() => _AmberPillButtonState();
}

class _AmberPillButtonState extends _PressableState<AmberPillButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final body = Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        gradient: BrandTokens.amberGradient,
        boxShadow: enabled ? BrandTokens.ctaAmberGlow : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
          ],
          Text(
            widget.label,
            style: BrandTokens.heading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: pressable(
        onTap: enabled ? widget.onPressed : null,
        child: body,
      ),
    );
  }
}

// Outlined ghost button: 1.5 dp brand-blue border, transparent fill.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;

  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color = BrandTokens.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: BrandTokens.heading(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
