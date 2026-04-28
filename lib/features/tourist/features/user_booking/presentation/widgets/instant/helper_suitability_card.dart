import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/responsive.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_search_result.dart';

/// Pass #5 redesign — modern, glanceable card for the "available helpers"
/// list. Replaces the previous flat row with:
///   • Floating gradient match-score badge
///   • Avatar with verified halo + status dot
///   • Stat row (rating, trips, distance) as compact chips
///   • Capability chips (languages, car, response)
///   • Inline price strip with subtle gradient and CTA chevron
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
    final r = Responsive.of(context);
    final scoreColor = _matchColor(helper.matchScore);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(r.gap, r.gap, r.gap, r.gapSM + 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandTokens.surfaceWhite,
                    BrandTokens.primaryBlue.withValues(alpha: 0.035),
                    BrandTokens.successGreen.withValues(alpha: 0.045),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.09),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: BrandTokens.shadowSoft,
                    blurRadius: 34,
                    spreadRadius: -10,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(
                        imageUrl: helper.profileImageUrl,
                        heroTag: 'helper-avatar-${helper.helperId}',
                        size: r.pick(compact: 52.0, phone: 60.0, tablet: 68.0),
                      ),
                      SizedBox(width: r.gapSM + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name with right padding so the floating
                            // score badge never overlaps the text.
                            Padding(
                              padding: const EdgeInsets.only(right: 80),
                              child: Text(
                                helper.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BrandTokens.heading(
                                  fontSize: r.fontTitle,
                                  fontWeight: FontWeight.w800,
                                  color: BrandTokens.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(height: r.gapXS),
                            _StatsRow(helper: helper),
                            SizedBox(height: r.gapXS),
                            _AvailabilityPill(helper: helper),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_capabilityChips(context).isNotEmpty) ...[
                    SizedBox(height: r.gapSM + 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _capabilityChips(context),
                    ),
                  ],
                  if (helper.suitabilityReasons.isNotEmpty) ...[
                    SizedBox(height: r.gapSM),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.gapSM),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: BrandTokens.borderSoft.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final reason in helper.suitabilityReasons.take(
                            2,
                          ))
                            _ReasonChip(text: reason),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: r.gapSM + 2),
                  _PriceStrip(helper: helper),
                ],
              ),
            ),
            // Floating match badge anchored to the top-right corner.
            Positioned(
              top: -8,
              right: 14,
              child: _MatchBadge(score: helper.matchScore, color: scoreColor),
            ),
            Positioned(
              left: 18,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [scoreColor, scoreColor.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _capabilityChips(BuildContext context) {
    final chips = <Widget>[];
    for (final lang in helper.languages.take(3)) {
      chips.add(
        _CapChip(
          icon: Icons.translate_rounded,
          label: lang.toUpperCase(),
          color: BrandTokens.primaryBlue,
        ),
      );
    }
    if (helper.hasCar) {
      chips.add(
        const _CapChip(
          icon: Icons.directions_car_rounded,
          label: 'Has car',
          color: BrandTokens.accentAmberText,
          background: BrandTokens.accentAmberSoft,
        ),
      );
    }
    if (helper.averageResponseTimeSeconds != null) {
      chips.add(
        _CapChip(
          icon: Icons.bolt_rounded,
          label: _responseLabel(helper.averageResponseTimeSeconds!),
          color: BrandTokens.successGreen,
        ),
      );
    }
    return chips;
  }

  static String _responseLabel(int s) {
    if (s < 60) return '~${s}s';
    return '~${s ~/ 60}m';
  }

  Color _matchColor(int score) {
    if (score >= 80) return BrandTokens.successGreen;
    if (score >= 60) return BrandTokens.primaryBlue;
    if (score >= 40) return BrandTokens.warningAmber;
    return BrandTokens.textSecondary;
  }
}

class _AvailabilityPill extends StatelessWidget {
  final HelperSearchResult helper;

  const _AvailabilityPill({required this.helper});

  @override
  Widget build(BuildContext context) {
    final isFast = (helper.averageResponseTimeSeconds ?? 9999) <= 120;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isFast ? BrandTokens.successGreen : BrandTokens.warningAmber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isFast ? 'Fast responder' : 'Available now',
          style: BrandTokens.body(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: BrandTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String heroTag;
  final double size;
  const _Avatar({
    required this.imageUrl,
    required this.heroTag,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Verified halo.
          Container(
            width: size + 6,
            height: size + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BrandTokens.successGreen, BrandTokens.primaryBlue],
              ),
            ),
          ),
          Positioned(
            top: 3,
            left: 3,
            child: Hero(
              tag: heroTag,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: AppNetworkImage(
                  imageUrl: imageUrl,
                  width: size - 4,
                  height: size - 4,
                  borderRadius: (size - 4) / 2,
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 16,
                color: BrandTokens.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final HelperSearchResult helper;
  const _StatsRow({required this.helper});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
            const SizedBox(width: 2),
            Text(
              helper.rating.toStringAsFixed(1),
              style: BrandTokens.numeric(
                fontSize: r.fontSmall + 1,
                fontWeight: FontWeight.w800,
                color: BrandTokens.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\u2022 ${helper.completedTrips} trips',
              style: BrandTokens.body(
                fontSize: r.fontSmall,
                color: BrandTokens.textSecondary,
              ),
            ),
          ],
        ),
        if (helper.distanceKm != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: BrandTokens.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                _formatDistance(helper.distanceKm!),
                style: BrandTokens.body(
                  fontSize: r.fontSmall,
                  color: BrandTokens.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}

class _MatchBadge extends StatelessWidget {
  final int score;
  final Color color;
  const _MatchBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            '$score%',
            style: BrandTokens.numeric(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'match',
            style: BrandTokens.body(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? background;
  const _CapChip({
    required this.icon,
    required this.label,
    required this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: BrandTokens.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String text;
  const _ReasonChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: BrandTokens.successGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 12,
            color: BrandTokens.successGreen,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: BrandTokens.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandTokens.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceStrip extends StatelessWidget {
  final HelperSearchResult helper;
  const _PriceStrip({required this.helper});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.gapSM + 2,
        vertical: r.gapSM + 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [BrandTokens.primaryBlue, BrandTokens.primaryBlueDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: BrandTokens.ctaBlueGlow,
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'EGP ${helper.estimatedPrice.toStringAsFixed(0)}',
            style: BrandTokens.numeric(
              fontSize: r.fontTitle,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '\u00b7 EGP ${helper.hourlyRate.toStringAsFixed(0)}/hr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrandTokens.body(
                fontSize: r.fontSmall,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BrandTokens.primaryBlue.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: BrandTokens.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
