import 'package:flutter/material.dart';

// Cupertino-style horizontal slide with parallax + opacity dim on the
// outgoing page. Used both as a `PageRoute` for Navigator.push() and
// as a `pageBuilder` factory for GoRouter routes.
class BrandPageRoute<T> extends PageRouteBuilder<T> {
  BrandPageRoute({
    required Widget child,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 235),
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: brandTransitionBuilder,
        );
}

/// Reusable transition builder that powers BrandPageRoute and the
/// global PageTransitionsBuilder. Incoming page slides in from the
/// right; outgoing page parallax-slides ~20 % to the left, scales to
/// 0.96, and fades to 0.5 opacity — same parallax feel as iOS.
Widget brandTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curve = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutQuint,
    reverseCurve: Curves.easeInQuint,
  );
  final secondary = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeOutQuint,
  );

  final slideIn = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(curve);

  final parallaxOut = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.2, 0.0),
  ).animate(secondary);

  final scaleOut = Tween<double>(begin: 1.0, end: 0.96).animate(secondary);
  final fadeOut = Tween<double>(begin: 1.0, end: 0.5).animate(secondary);

  return SlideTransition(
    position: parallaxOut,
    child: ScaleTransition(
      scale: scaleOut,
      child: FadeTransition(
        opacity: fadeOut,
        child: SlideTransition(
          position: slideIn,
          child: child,
        ),
      ),
    ),
  );
}

/// PageTransitionsBuilder that replaces the default Material zoom on
/// every platform. Plug into ThemeData.pageTransitionsTheme.
class BrandPageTransitionsBuilder extends PageTransitionsBuilder {
  const BrandPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return brandTransitionBuilder(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
