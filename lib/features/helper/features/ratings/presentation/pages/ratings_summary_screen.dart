import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/helper_ratings_cubit.dart';

class RatingsSummaryScreen extends StatefulWidget {
  const RatingsSummaryScreen({super.key});

  @override
  State<RatingsSummaryScreen> createState() => _RatingsSummaryScreenState();
}

class _RatingsSummaryScreenState extends State<RatingsSummaryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperRatingsCubit>().loadSummaryAndRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating Analytics')),
      body: BlocBuilder<HelperRatingsCubit, HelperRatingsState>(
        builder: (context, state) {
          if (state is RatingsLoading) return const Center(child: CircularProgressIndicator());
          if (state is RatingsError) return Center(child: Text(state.message));

          if (state is RatingsLoaded && state.summary != null) {
            final summary = state.summary!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeaderCard(context, summary),
                  const SizedBox(height: 24),
                  _buildDistributionCard(context, summary),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, dynamic summary) {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Text(
              summary.averageStars.toStringAsFixed(1),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < summary.averageStars.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Based on ${summary.totalCount} ratings',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard(BuildContext context, dynamic summary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...List.generate(5, (index) {
              final starCount = 5 - index;
              final count = summary.distribution[starCount] ?? 0;
              final percentage = summary.totalCount == 0 ? 0.0 : count / summary.totalCount;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Row(
                        children: [
                          Text('$starCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text('$count', textAlign: TextAlign.end, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
