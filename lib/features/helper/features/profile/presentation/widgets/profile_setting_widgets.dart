import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_color.dart';

/// A grouped section in the helper profile / account control center pages.
/// Renders a small uppercase title followed by a rounded surface that hosts
/// a list of [ProfileSettingItem] widgets separated by hairline dividers.
class ProfileSettingGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const ProfileSettingGroup({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 20, 10),
          child: Text(
            title,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 68),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: palette.border,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single tappable row inside a [ProfileSettingGroup].
class ProfileSettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileSettingItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(
                        alpha: palette.isDark ? 0.22 : 0.16,
                      ),
                      iconColor.withValues(
                        alpha: palette.isDark ? 0.10 : 0.06,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        fontSize: 14.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? palette.primary).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor ?? palette.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.textMuted,
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
