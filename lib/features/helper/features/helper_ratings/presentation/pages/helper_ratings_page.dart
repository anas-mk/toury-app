import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_ratings_cubits.dart';
import '../widgets/rating_widgets.dart';

class HelperRatingsPage extends StatefulWidget {
  const HelperRatingsPage({super.key});

  @override
  State<HelperRatingsPage> createState() => _HelperRatingsPageState();
}

class _HelperRatingsPageState extends State<HelperRatingsPage> {
  late final HelperRatingsCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperRatingsCubit>()..load();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ratings & Reviews',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'How travelers rate your service',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => _cubit.refresh(),
          color: AppColor.primaryColor,
          child: BlocBuilder<HelperRatingsCubit, HelperRatingsState>(
            builder: (context, state) {
              if (state is HelperRatingsLoading) {
                return _buildLoading();
              } else if (state is HelperRatingsLoaded) {
                return _buildContent(state);
              } else if (state is HelperRatingsError) {
                return _buildError(state.message);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(HelperRatingsLoaded state) {
    if (state.reviews.isEmpty) {
      return _buildEmptyState(state);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: state.reviews.length + 2, // Header + Summary + List + Loader
      itemBuilder: (context, index) {
        if (index == 0) {
          return RatingSummaryCard(summary: state.summary);
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Recent Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
        
        final reviewIndex = index - 2;
        if (reviewIndex < state.reviews.length) {
          return ReviewListTile(review: state.reviews[reviewIndex]);
        }

        return state.hasReachedMax
            ? const SizedBox(height: 40)
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColor.primaryColor),
                ),
              );
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColor.primaryColor),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColor.errorColor, size: 60),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _cubit.load(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primaryColor),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HelperRatingsLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RatingSummaryCard(summary: state.summary),
            const SizedBox(height: 100),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.reviews_outlined, color: AppColor.primaryColor, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete trips to receive feedback\nfrom travelers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
