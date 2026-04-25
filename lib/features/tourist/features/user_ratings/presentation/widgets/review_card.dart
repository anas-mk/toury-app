import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../domain/entities/rating_entity.dart';

class ReviewCard extends StatelessWidget {
  final RatingEntity rating;

  const ReviewCard({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: Colors.amber,
                  );
                }),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(rating.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              rating.comment,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
          if (rating.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rating.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
