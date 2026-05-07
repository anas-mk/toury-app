import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/widgets/app_bottom_nav.dart';

class HomeLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: loc.translate('home'),
          ),
          AppBottomNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: loc.translate('trips'),
          ),
          AppBottomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: loc.translate('wallet'),
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: loc.translate('account'),
          ),
        ],
      ),
    );
  }
}
