import 'package:flutter/material.dart';

class ReputationCard extends StatelessWidget {
  final double rating;
  final VoidCallback onTap;

  const ReputationCard({super.key, required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFAB40).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFFFFAB40), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Reputation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'View your ratings and feedback',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFFFFAB40),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Rating',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
