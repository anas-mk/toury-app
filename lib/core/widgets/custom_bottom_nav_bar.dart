// lib/core/widgets/custom_bottom_nav_bar.dart
//
// Legacy bottom nav shim. The active shells (HomeLayout +
// HelperHomeLayout) now use [AppBottomNavBar] directly. This widget is
// preserved as a thin wrapper because the symbol is still exported from
// the public widget barrel and could be imported by older feature
// branches.

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import 'app_bottom_nav.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AppBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: loc.translate('home'),
        ),
        AppBottomNavItem(
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
          label: loc.translate('explore'),
        ),
        AppBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: loc.translate('profile'),
        ),
      ],
    );
  }
}
