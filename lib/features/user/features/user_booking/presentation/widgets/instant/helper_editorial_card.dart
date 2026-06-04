import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/helper_search_result.dart';

/// Editorial-style helper card used by the redesigned
/// `InstantHelpersListPage`. Mirrors the RAFIQ HTML mockup:
///   • 72×72 circular avatar with green online dot
///   • Name + ★ rating + trips + Verified pill
///   • 2-column grid: languages + distance | hourly rate
///   • Outlined "View Profile" + filled "Book Now" CTA row
///
/// All animations and interactions are local — the card is pure
/// presentation that calls back via [onView] and [onBook].
class HelperEditorialCard extends StatefulWidget {
  final HelperSearchResult helper;
  final VoidCallback onView;
  final VoidCallback onBook;

  const HelperEditorialCard({
    super.key,
    required this.helper,
    required this.onView,
    required this.onBook,
  });

  @override
  State<HelperEditorialCard> createState() => _HelperEditorialCardState();
}

class _HelperEditorialCardState extends State<HelperEditorialCard> {
  bool _pressed = false;

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapCancel() => setState(() => _pressed = false);
  void _onTapUp(_) => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final h = widget.helper;
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapCancel: _onTapCancel,
        onTapUp: _onTapUp,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onView();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: BrandTokens.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E4DF)),
            boxShadow: const [
              BoxShadow(
                color: BrandTokens.shadowSoft,
                blurRadius: 30,
                spreadRadius: -8,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IdentityRow(helper: h),
              const SizedBox(height: 18),
              _MetaRow(helper: h),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE8E4DF)),
              const SizedBox(height: 16),
              _ActionRow(
                onView: widget.onView,
                onBook: widget.onBook,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top row: avatar + name + rating + verified
// ─────────────────────────────────────────────────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final HelperSearchResult helper;
  const _IdentityRow({required this.helper});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          imageUrl: helper.profileImageUrl,
          heroTag: 'helper-avatar-${helper.helperId}',
          showOnlineDot: helper.canAcceptInstant,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helper.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: BrandTokens.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RatingTripsRow(
                      rating: helper.rating,
                      trips: helper.completedTrips,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _VerifiedChip(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String heroTag;
  final bool showOnlineDot;
  const _Avatar({
    required this.imageUrl,
    required this.heroTag,
    required this.showOnlineDot,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Hero(
            tag: heroTag,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: BrandTokens.surfaceWhite,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: AppNetworkImage(
                  imageUrl: imageUrl,
                  width: 68,
                  height: 68,
                  borderRadius: 34,
                ),
              ),
            ),
          ),
          if (showOnlineDot)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BrandTokens.surfaceWhite,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatingTripsRow extends StatelessWidget {
  final double rating;
  final int trips;
  const _RatingTripsRow({required this.rating, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Yellow star + numeric rating, matching `text-secondary-container`
        // in the mockup (the saturated orange/amber).
        const Text(
          '★ ',
          style: TextStyle(
            color: Color(0xFFFE9331),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          context.localizeNumber(rating, decimals: 1),
          style: const TextStyle(
            color: Color(0xFFFE9331),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '·',
          style: TextStyle(
            color: BrandTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${context.localizeNumber(trips)} trips',
          style: const TextStyle(
            color: BrandTokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFECF5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: BrandTokens.primaryBlue,
          ),
          SizedBox(width: 4),
          Text(
            'VERIFIED',
            style: TextStyle(
              color: BrandTokens.primaryBlue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Middle row: languages + distance | price
// ─────────────────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final HelperSearchResult helper;
  const _MetaRow({required this.helper});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LanguagesRow(languages: helper.languages),
              const SizedBox(height: 12),
              _DistanceRow(distanceKm: helper.distanceKm, hasCar: helper.hasCar),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PriceBlock(
          estimatedPrice: helper.estimatedPrice,
          hourlyRate: helper.hourlyRate,
        ),
      ],
    );
  }
}

class _LanguagesRow extends StatelessWidget {
  final List<String> languages;
  const _LanguagesRow({required this.languages});

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(
          Icons.translate_rounded,
          size: 18,
          color: BrandTokens.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final lang in languages.take(3))
                _LangPill(label: lang.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  const _LangPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E1EA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF464652),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DistanceRow extends StatelessWidget {
  final double? distanceKm;
  final bool hasCar;
  const _DistanceRow({required this.distanceKm, required this.hasCar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          size: 18,
          color: BrandTokens.textSecondary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            distanceKm != null
                ? '${_formatDistance(context, distanceKm!)} away'
                : 'Distance unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BrandTokens.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasCar) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.directions_car_rounded,
            size: 16,
            color: BrandTokens.accentAmberText,
          ),
        ],
      ],
    );
  }

  String _formatDistance(BuildContext context, double km) {
    if (km < 1) return '${context.localizeNumber((km * 1000).round())} m';
    return '${context.localizeNumber(km, decimals: 1)} km';
  }
}

class _PriceBlock extends StatelessWidget {
  final double estimatedPrice;
  // Nullable: a freshly migrated `HelperSearchResult` may not carry
  // an hourly rate (the search endpoint started returning it as
  // optional in the user/ refactor). Skip the secondary line cleanly
  // when missing instead of crashing on `null!`.
  final double? hourlyRate;
  const _PriceBlock({
    required this.estimatedPrice,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The mockup uses `text-secondary` which is the warm brown. We
        // map it to our amber-text token for visual parity (warm,
        // attention-grabbing without competing with the primary CTA).
        Text(
          '~${_formatPrice(context, estimatedPrice)} EGP',
          style: const TextStyle(
            color: Color(0xFF924C00),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (hourlyRate != null) ...[
          const SizedBox(height: 2),
          Text(
            '${_formatPrice(context, hourlyRate!)} EGP/hr',
            style: const TextStyle(
              color: BrandTokens.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(BuildContext context, double v) {
    if (v >= 1000) {
      final k = v / 1000;
      final raw = k % 1 == 0 ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
      return context.localizeDigits(raw);
    }
    return context.localizeNumber(v, decimals: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row: View Profile (outlined) + Book Now (filled)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onBook;
  const _ActionRow({required this.onView, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'View Profile',
            onTap: onView,
            filled: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillButton(
            label: 'Book Now',
            onTap: onBook,
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _PillButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? BrandTokens.primaryBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(40),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: filled ? BrandTokens.primaryBlue : Colors.transparent,
            border: filled
                ? null
                : Border.all(color: BrandTokens.primaryBlue, width: 1.4),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color:
                          BrandTokens.primaryBlue.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color:
                    filled ? Colors.white : BrandTokens.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
