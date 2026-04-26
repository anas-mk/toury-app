import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/helper_rating_entities.dart';

class RatingSummaryCard extends StatelessWidget {
  final RatingsSummaryEntity summary;

  const RatingSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.averageStars.toStringAsFixed(1),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < summary.averageStars.floor()
                            ? Icons.star_rounded
                            : index < summary.averageStars
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded,
                        color: AppColor.warningColor,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalCount} reviews',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceXL),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final starCount = 5 - index;
                    final count = summary.distribution[starCount] ?? 0;
                    final progress = summary.totalCount == 0 ? 0.0 : count / summary.totalCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$starCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: isDark ? Colors.white10 : Colors.black38,
                                color: AppColor.accentColor,
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: AppColor.accentColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: AppColor.accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Top Rated Captain',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColor.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewListTile extends StatelessWidget {
  final RatingEntity review;

  const ReviewListTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.authorAvatarUrl.isNotEmpty
                    ? NetworkImage(review.authorAvatarUrl)
                    : null,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: review.authorAvatarUrl.isEmpty
                    ? Text(
                        review.authorDisplayName[0],
                        style: TextStyle(
                          color: theme.colorScheme.primary, 
                          fontWeight: FontWeight.bold
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorDisplayName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star_rounded,
                              color: index < review.stars ? AppColor.warningColor : theme.disabledColor.withOpacity(0.1),
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(review.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  review.bookingType.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark ? AppColor.darkText : AppColor.lightText,
              ),
            ),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.tags.map((tag) => TagChip(label: tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black38),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected 
                ? theme.colorScheme.onPrimary 
                : (isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class StarSelector extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const StarSelector({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isSelected = rating >= starValue;
        return IconButton(
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isSelected ? AppColor.warningColor : theme.disabledColor.withOpacity(0.2),
            size: 44,
          ),
          onPressed: () => onRatingChanged(starValue),
        );
      }),
    );
  }
}
