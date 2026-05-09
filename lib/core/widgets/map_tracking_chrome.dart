// Shared visual chrome for traveler + helper map / tracking flows.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

enum MapFloatingGlassTone { lightOnMap, darkOnMap }

class MapFloatingGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final MapFloatingGlassTone tone;

  const MapFloatingGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tone = MapFloatingGlassTone.lightOnMap,
  });

  static const double tapSize = AppSize.icon2Xl + AppSize.iconSm;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    switch (tone) {
      case MapFloatingGlassTone.lightOnMap:
        return ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Material(
              color: palette.surfaceElevated.withValues(alpha: 0.88),
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: tapSize,
                  height: tapSize,
                  child: Icon(
                    icon,
                    color: palette.textPrimary,
                    size: AppSize.iconLg,
                  ),
                ),
              ),
            ),
          ),
        );
      case MapFloatingGlassTone.darkOnMap:
        return ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.black.withValues(alpha: 0.26),
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: tapSize,
                  height: tapSize,
                  child: Icon(icon, color: Colors.white, size: AppSize.iconLg),
                ),
              ),
            ),
          ),
        );
    }
  }
}

class MapTrackingDragHandle extends StatelessWidget {
  const MapTrackingDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Center(
        child: Container(
          width: AppSpacing.mega + AppSpacing.sm,
          height: AppSpacing.xxs + AppSpacing.xs + 1,
          decoration: BoxDecoration(
            color: palette.border.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

class MapTrackingSheetSurface extends StatelessWidget {
  final Widget child;

  const MapTrackingSheetSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        border: Border.all(
          color: palette.border.withValues(alpha: palette.isDark ? 0.35 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.textPrimary.withValues(
              alpha: palette.isDark ? 0.32 : 0.10,
            ),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MapRouteInfoChip extends StatelessWidget {
  final String distance;
  final String duration;

  const MapRouteInfoChip({
    super.key,
    required this.distance,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xxl + AppSpacing.xs),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceElevated.withValues(
              alpha: palette.isDark ? 0.78 : 0.94,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.xxl + AppSpacing.xs),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: palette.textPrimary.withValues(alpha: 0.08),
                blurRadius: AppSpacing.xl + AppSpacing.sm,
                offset: Offset(0, AppSpacing.xs + AppSpacing.xxs),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.straighten_rounded,
                size: AppSize.iconMd,
                color: palette.primary,
              ),
              SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Text(distance, style: textStyle),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + AppSpacing.sm,
                ),
                width: AppSize.hairline,
                height: AppSpacing.lg + AppSpacing.xs,
                color: palette.border,
              ),
              Icon(
                Icons.schedule_rounded,
                size: AppSize.iconMd,
                color: palette.primary,
              ),
              SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Text(duration, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class MapTrackingLayout {
  MapTrackingLayout._();

  static double floatingButtonBottomInset(
    BuildContext context, {
    required double sheetPeekFraction,
    double gutter = AppSpacing.lg,
  }) {
    return MediaQuery.sizeOf(context).height * sheetPeekFraction + gutter;
  }

  static TrackingSheetExtents sheetExtents(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    if (shortest < 360) {
      return const TrackingSheetExtents(initial: 0.36, min: 0.22, max: 0.66);
    }
    if (shortest > 560) {
      return const TrackingSheetExtents(initial: 0.34, min: 0.20, max: 0.58);
    }
    return const TrackingSheetExtents(initial: 0.32, min: 0.18, max: 0.62);
  }

  static TrackingSheetExtents helperSheetExtents(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    if (shortest < 360) {
      return const TrackingSheetExtents(initial: 0.42, min: 0.26, max: 0.74);
    }
    if (shortest > 560) {
      return const TrackingSheetExtents(initial: 0.36, min: 0.20, max: 0.68);
    }
    return const TrackingSheetExtents(initial: 0.38, min: 0.22, max: 0.72);
  }
}

class TrackingSheetExtents {
  final double initial;
  final double min;
  final double max;

  const TrackingSheetExtents({
    required this.initial,
    required this.min,
    required this.max,
  });
}
