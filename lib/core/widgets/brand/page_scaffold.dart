import 'package:flutter/material.dart';

import '../../theme/brand_tokens.dart';

// Standard page chrome: BgSoft background, SafeArea, optional sticky
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
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      backgroundColor: backgroundColor ?? BrandTokens.bgSoft,
      body: body,
      bottomNavigationBar: bottomCta == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: bottomCta,
              ),
            ),
    );
  }
}
