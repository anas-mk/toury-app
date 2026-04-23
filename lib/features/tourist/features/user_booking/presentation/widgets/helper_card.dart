import 'package:flutter/material.dart';
import '../../domain/entities/helper_entity.dart';

class HelperCard extends StatelessWidget {
  final HelperEntity helper;
  final VoidCallback onViewProfile;
  final VoidCallback onBook;

  const HelperCard({
    super.key,
    required this.helper,
    required this.onViewProfile,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: helper.profileImageUrl != null
                  ? NetworkImage(helper.profileImageUrl!)
                  : null,
              child: helper.profileImageUrl == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helper.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${helper.rating} (${helper.reviewsCount} reviews)'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('\$${helper.pricePerHour}/hr', style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
            Column(
              children: [
                OutlinedButton(
                  onPressed: onViewProfile,
                  child: const Text('Profile'),
                ),
                ElevatedButton(
                  onPressed: onBook,
                  child: const Text('Book'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
