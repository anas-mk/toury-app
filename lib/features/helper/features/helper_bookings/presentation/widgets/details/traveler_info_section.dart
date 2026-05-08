// Modern traveler info section showing name, country, language, and quick
// "Chat" / "Notes" actions. Used inside the booking-details page.

import 'package:flutter/material.dart';

import '../../../../../../../core/config/api_config.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../domain/entities/helper_booking_entities.dart';

class TravelerInfoSection extends StatelessWidget {
  final HelperBooking booking;
  final VoidCallback? onChat;

  const TravelerInfoSection({
    super.key,
    required this.booking,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final hasNotes = (booking.notes ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(
                  name: booking.travelerName,
                  imageUrl: booking.travelerImage,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              booking.travelerName.isEmpty
                                  ? 'Traveler'
                                  : booking.travelerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: palette.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Booking Traveler',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onChat != null) _ChatButton(onTap: onChat!),
              ],
            ),
            if (booking.travelerCountry != null || booking.language != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (booking.travelerCountry != null)
                    _MetaChip(
                      icon: Icons.public_rounded,
                      label: booking.travelerCountry!,
                    ),
                  if (booking.language != null)
                    _MetaChip(
                      icon: Icons.translate_rounded,
                      label: booking.language!,
                    ),
                  _MetaChip(
                    icon: booking.isInstant
                        ? Icons.flash_on_rounded
                        : Icons.event_outlined,
                    label: booking.isInstant ? 'Instant' : 'Scheduled',
                    accent: booking.isInstant
                        ? palette.warning
                        : palette.primary,
                  ),
                ],
              ),
            ],
            if (hasNotes) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: AppSize.iconSm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        booking.notes!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final resolved = ApiConfig.resolveImageUrl(imageUrl);

    final fallback = Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: theme.textTheme.titleLarge?.copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: AppSize.avatarLg + 4,
      height: AppSize.avatarLg + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary,
            Color.lerp(palette.primary, palette.success, 0.55)!,
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surfaceElevated,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Container(
              color: palette.primarySoft,
              child: resolved.isNotEmpty
                  ? Image.network(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallback,
                    )
                  : fallback,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;
  const _MetaChip({required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final color = accent ?? palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.iconXs + 2, color: color),
          const SizedBox(width: AppSpacing.xs + 1),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: palette.primary.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.chat_bubble_rounded,
            color: palette.primary,
            size: AppSize.iconMd,
          ),
        ),
      ),
    );
  }
}
