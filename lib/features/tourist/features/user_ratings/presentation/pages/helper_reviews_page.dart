import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../cubit/user_ratings_cubit.dart';
import '../cubit/user_ratings_state.dart';
import '../widgets/rating_summary_widget.dart';
import '../widgets/review_card.dart';

class HelperReviewsPage extends StatelessWidget {
  final String helperId;
  final String helperName;

  const HelperReviewsPage({
    super.key,
    required this.helperId,
    required this.helperName,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<UserRatingsCubit>()
            ..getHelperSummary(helperId)
            ..getHelperRatings(helperId),
        ),
      ],
      child: Scaffold(
        appBar: BasicAppBar(
          title: '$helperName\'s Reviews',
          showBackButton: true,
        ),
        body: BlocBuilder<UserRatingsCubit, UserRatingsState>(
          builder: (context, state) {
            if (state is UserRatingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: BlocBuilder<UserRatingsCubit, UserRatingsState>(
                      buildWhen: (prev, curr) => curr is RatingSummaryLoaded,
                      builder: (context, state) {
                        if (state is RatingSummaryLoaded) {
                          return RatingSummaryWidget(summary: state.summary);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'ALL REVIEWS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                BlocBuilder<UserRatingsCubit, UserRatingsState>(
                  buildWhen: (prev, curr) => curr is UserRatingsLoaded || curr is UserRatingsError,
                  builder: (context, state) {
                    if (state is UserRatingsLoaded) {
                      if (state.ratings.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(child: Text('No reviews yet')),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ReviewCard(rating: state.ratings[index]),
                              );
                            },
                            childCount: state.ratings.length,
                          ),
                        ),
                      );
                    }
                    if (state is UserRatingsError) {
                      return SliverFillRemaining(
                        child: Center(child: Text(state.message)),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }
}
