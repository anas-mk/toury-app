import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_search_result.dart';

class HelperSuitabilityCard extends StatelessWidget {
  final HelperSearchResult helper;
  final VoidCallback onTap;

  const HelperSuitabilityCard({
    super.key,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _matchColor(helper.matchScore);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AppNetworkImage(
                            imageUrl: helper.profileImageUrl,
                            width: 60,
                            height: 60,
                            borderRadius: 30,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColor.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // leave room for the score badge in the corner
                            Padding(
                              padding: const EdgeInsets.only(right: 70),
                              child: Text(
                                helper.fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFF5A623),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  helper.rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceSM),
                                Text(
                                  '${helper.completedTrips} trips',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColor.lightTextSecondary,
                                  ),
                                ),
                                if (helper.distanceKm != null) ...[
                                  const SizedBox(width: AppTheme.spaceSM),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColor.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatDistance(helper.distanceKm!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColor.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Wrap(
                    spacing: AppTheme.spaceXS,
                    runSpacing: AppTheme.spaceXS,
                    children: [
                      for (final lang in helper.languages.take(3))
                        _Chip(
                          icon: Icons.translate_rounded,
                          label: lang.toUpperCase(),
                          color: AppColor.secondaryColor,
                        ),
                      if (helper.hasCar)
                        const _Chip(
                          icon: Icons.directions_car_rounded,
                          label: 'Has car',
                          color: AppColor.warningColor,
                        ),
                      if (helper.averageResponseTimeSeconds != null)
                        _Chip(
                          icon: Icons.bolt_rounded,
                          label: _formatResponse(
                              helper.averageResponseTimeSeconds!),
                          color: AppColor.accentColor,
                        ),
                    ],
                  ),
                  if (helper.suitabilityReasons.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceSM),
                    Wrap(
                      spacing: AppTheme.spaceXS,
                      runSpacing: AppTheme.spaceXS,
                      children: [
                        for (final reason in helper.suitabilityReasons.take(2))
                          _Reason(reason),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceMD),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMD,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: AppColor.accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EGP ${helper.estimatedPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColor.accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Â· EGP ${helper.hourlyRate.toStringAsFixed(0)}/hr',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColor.accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColor.accentColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _MatchScoreBadge(
                score: helper.matchScore,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String _formatResponse(int s) {
    if (s < 60) return '~${s}s response';
    return '~${s ~/ 60}m response';
  }

  Color _matchColor(int score) {
    if (score >= 80) return AppColor.accentColor;
    if (score >= 60) return AppColor.secondaryColor;
    if (score >= 40) return AppColor.warningColor;
    return AppColor.lightTextSecondary;
  }
}

class _MatchScoreBadge extends StatelessWidget {
  final int score;
  final Color color;
  const _MatchScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            '$score% match',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  final String text;
  const _Reason(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColor.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: AppColor.accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColor.accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
