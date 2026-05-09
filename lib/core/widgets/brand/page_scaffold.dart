import 'package:flutter/material.dart';

import '../../theme/app_color.dart';
import '../../theme/app_dimens.dart';

// Standard page chrome: theme-aware scaffold background, optional sticky
// bottom CTA. Pages don't manually call SafeArea anymore.
class PageScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomCta;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const PageScaffold({
    super.key,
    required this.body,
    this.bottomCta,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      backgroundColor: backgroundColor ?? palette.scaffold,
      body: body,
      bottomNavigationBar: bottomCta == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  AppSpacing.sm,
                  AppSpacing.pageGutter,
                  AppSpacing.md,
                ),
                child: bottomCta,
              ),
            ),
    );
  }
}
