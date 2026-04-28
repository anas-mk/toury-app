import 'package:flutter/material.dart';

// Organic blob bottom edge for hero headers. No straight horizontal
// edge at the bottom; the shape dips on the left, rises on the right.
class HeroBlobShape extends StatelessWidget {
  final Widget child;
  final double height;

  const HeroBlobShape({super.key, required this.child, this.height = 280});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _HeroBlobClipper(),
      child: SizedBox(height: height, child: child),
    );
  }
}

class _HeroBlobClipper extends CustomClipper<Path> {
  const _HeroBlobClipper();

  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 50);
    p.cubicTo(
      size.width * 0.25, size.height - 10,
      size.width * 0.55, size.height - 80,
      size.width * 0.75, size.height - 40,
    );
    p.cubicTo(
      size.width * 0.9, size.height - 20,
      size.width, size.height - 50,
      size.width, size.height - 70,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Mirror of the hero blob, used at the top edge of bottom sheets so the
// edge between the map (or list below) and the sheet is organic too.
class SheetBlobShape extends StatelessWidget {
  final Widget child;

  const SheetBlobShape({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _SheetBlobClipper(),
      child: child,
    );
  }
}

class _SheetBlobClipper extends CustomClipper<Path> {
  const _SheetBlobClipper();

  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 28);
    p.cubicTo(
      size.width * 0.25, 4,
      size.width * 0.55, 56,
      size.width * 0.75, 18,
    );
    p.cubicTo(
      size.width * 0.9, 2,
      size.width, 24,
      size.width, 36,
    );
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
