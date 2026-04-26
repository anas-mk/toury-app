import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:toury/features/tourist/features/user_ratings/presentation/cubit/user_ratings_cubit.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/rating_entity.dart';
import '../cubit/user_ratings_state.dart';

class HelperReviewsPage extends StatelessWidget {
  final String helperId;
  final String? helperName;

  const HelperReviewsPage({
    super.key, 
    required this.helperId,
    this.helperName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => sl<UserRatingsCubit>()..loadHelperRatings(helperId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Helper Reviews'),
        ),
        body: BlocBuilder<UserRatingsCubit, UserRatingsState>(
          builder: (context, state) {
            if (state is RatingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RatingLoaded) {
              return CustomScrollView(
                slivers: [
                  // Overall Rating Summary
                  SliverToBoxAdapter(
                    child: _buildRatingSummary(theme, state.summary),
                  ),
                  
                  // Reviews List
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    sliver: state.ratings.isEmpty
                        ? const SliverFillRemaining(child: Center(child: Text('No reviews yet')))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildReviewCard(theme, state.ratings[index]),
                              childCount: state.ratings.length,
                            ),
                          ),
                  ),
                ],
              );
            }
            if (state is RatingError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildRatingSummary(ThemeData theme, RatingSummaryEntity? summary) {
    if (summary == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        border: const Border(bottom: BorderSide(color: AppColor.lightBorder)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.averageStars.toStringAsFixed(1),
                style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColor.primaryColor),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded, 
                  color: i < summary.averageStars ? Colors.amber : Colors.grey[300],
                  size: 20,
                )),
              ),
              const SizedBox(height: 4),
              Text('${summary.averageStars} Reviews', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(width: AppTheme.space2XL),
          // Simple distribution chart (Mock)
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (star == 5) ? 0.8 : (star == 4 ? 0.15 : 0.05),
                          backgroundColor: Colors.grey[200],
                          color: Colors.amber,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
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
    );
  }

  Widget _buildReviewCard(ThemeData theme, RatingEntity rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rating.authorId, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                DateFormat('MMM dd, yyyy').format(rating.createdAt),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          Row(
            children: List.generate(5, (i) => Icon(
              Icons.star_rounded, 
              color: i < rating.stars ? Colors.amber : Colors.grey[300],
              size: 16,
            )),
          ),
          const SizedBox(height: 8),
          Text(rating.comment, style: theme.textTheme.bodyMedium),
          if (rating.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: rating.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 10, color: AppColor.accentColor)),
              )).toList(),
            ),
          ],
          const Divider(height: AppTheme.spaceXL),
        ],
      ),
    );
  }
}
