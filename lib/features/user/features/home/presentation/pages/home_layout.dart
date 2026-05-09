import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/brand_tokens.dart';

class HomeLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: BrandTokens.bgSoft,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _TouristBottomNav(
        currentIndex: current,
        onTap: (i) => navigationShell.goBranch(i),
      ),
    );
  }
}

class _TouristBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TouristBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  // Icons matched to the design: home_max / map / auto_stories / person
  static const _icons = [
    (outline: Icons.home_max_outlined,      filled: Icons.home_max),
    (outline: Icons.map_outlined,           filled: Icons.map_rounded),
    (outline: Icons.auto_stories,           filled: Icons.auto_stories),
    (outline: Icons.person_outline_rounded, filled: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Row centres the pill horizontally without expanding the nav bar height.
    // Do NOT use alignment on the outer wrapper — Container(alignment:center)
    // fills the entire bottomNavigationBar slot, pushing the pill mid-screen.
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: bottomPad > 0 ? bottomPad + 8 : 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              // Matches design: shadow-[0_8px_30px_rgb(27,35,126,0.06)]
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F1B237E),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_icons.length, (i) {
                final active = i == currentIndex;
                return Padding(
                  // gap-8 = 32 px between buttons (left gap on all except first)
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 32),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    // 9 px padding → 26 + 18 = 44 px minimum tap target
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: AnimatedScale(
                        scale: active ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            active ? _icons[i].filled : _icons[i].outline,
                            key: ValueKey(active),
                            color: active
                                ? BrandTokens.primaryBlue
                                : BrandTokens.textMuted,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
