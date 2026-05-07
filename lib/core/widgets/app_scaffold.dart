import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// Theme-aware screen shell (prefer over raw [Scaffold] background colors).
/// For layouts with a sticky bottom CTA, use [PageScaffold] in
/// `brand/page_scaffold.dart`.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? bodyPadding;
  final bool safeAreaBody;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.bodyPadding,
    this.safeAreaBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    Widget content = body;
    if (bodyPadding != null) {
      content = Padding(padding: bodyPadding!, child: content);
    }
    if (safeAreaBody) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      backgroundColor: backgroundColor ?? palette.scaffold,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
