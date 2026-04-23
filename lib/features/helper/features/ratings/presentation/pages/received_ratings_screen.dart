import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/helper_ratings_cubit.dart';

class ReceivedRatingsScreen extends StatefulWidget {
  const ReceivedRatingsScreen({super.key});

  @override
  State<ReceivedRatingsScreen> createState() => _ReceivedRatingsScreenState();
}

class _ReceivedRatingsScreenState extends State<ReceivedRatingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperRatingsCubit>().loadSummaryAndRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Received Ratings')),
      body: BlocBuilder<HelperRatingsCubit, HelperRatingsState>(
        builder: (context, state) {
          if (state is RatingsLoading) return const Center(child: CircularProgressIndicator());
          if (state is RatingsError) return Center(child: Text(state.message));
          
          if (state is RatingsLoaded) {
            if (state.receivedRatings.isEmpty) {
              return const Center(child: Text('No ratings received yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.receivedRatings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rating = state.receivedRatings[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: rating.reviewerImage != null ? NetworkImage(rating.reviewerImage!) : null,
                              child: rating.reviewerImage == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rating.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(rating.createdAt),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.stars.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (rating.comment != null) ...[
                          const SizedBox(height: 12),
                          Text(rating.comment!, style: const TextStyle(color: Colors.black87)),
                        ],
                        if (rating.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: rating.tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(tag, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
