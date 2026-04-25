import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/helper_rating_entities.dart';

class RatingSummaryCard extends StatelessWidget {
  final RatingsSummaryEntity summary;

  const RatingSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2340), Color(0xFF141829)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.averageStars.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
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
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalCount} reviews',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
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
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white10,
                                color: Colors.amber,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C896).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF00C896), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Top Rated Captain',
                  style: TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold, fontSize: 13),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
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
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                child: review.authorAvatarUrl.isEmpty
                    ? Text(
                        review.authorDisplayName[0],
                        style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star_rounded,
                              color: index < review.stars ? Colors.amber : Colors.white10,
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(review.createdAt),
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.bookingType.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isSelected = rating >= starValue;
        return IconButton(
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isSelected ? Colors.amber : Colors.white24,
            size: 40,
          ),
          onPressed: () => onRatingChanged(starValue),
        );
      }),
    );
  }
}
