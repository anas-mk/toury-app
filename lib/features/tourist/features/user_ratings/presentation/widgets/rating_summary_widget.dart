import 'package:flutter/material.dart';
import '../../domain/entities/rating_entity.dart';

class RatingSummaryWidget extends StatelessWidget {
  final RatingSummaryEntity summary;

  const RatingSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAverageSection(),
          const SizedBox(width: 24),
          Expanded(child: _buildDistributionBars()),
        ],
      ),
    );
  }

  Widget _buildAverageSection() {
    return Column(
      children: [
        Text(
          summary.averageStars.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < summary.averageStars.floor()
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 16,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '${summary.totalCount} reviews',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDistributionBars() {
    return Column(
      children: List.generate(5, (index) {
        final starCount = 5 - index;
        final count = summary.distribution[starCount] ?? 0;
        final percentage = summary.totalCount > 0 ? count / summary.totalCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$starCount',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      starCount >= 4 ? Colors.amber : (starCount >= 3 ? Colors.amber.shade300 : Colors.grey.shade400),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
