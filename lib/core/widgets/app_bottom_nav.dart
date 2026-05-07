// lib/core/widgets/app_bottom_nav.dart
//
// Unified bottom navigation bar shared by the user (HomeLayout) and
// helper (HelperHomeLayout) shells.
//
// Goals:
//   - Single source of truth for tab styling, selected/unselected colors,
//     elevation, and label typography.
//   - Theme-aware: respects light AND dark mode.
//   - Accessible: 64 px tall touch targets, semantic labels.
//   - Visually polished: subtle pill highlight on the active item that
//     animates between tabs.

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSize.bottomNav,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavTile(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                    palette: palette,
                    theme: theme,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final AppColors palette;
  final ThemeData theme;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.palette,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? palette.primary : palette.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? AppSpacing.md : AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? palette.primarySoft.withValues(
                        alpha: palette.isDark ? 0.6 : 1.0,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? (item.activeIcon ?? item.icon) : item.icon,
                    color: color,
                    size: AppSize.iconLg,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              item.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
