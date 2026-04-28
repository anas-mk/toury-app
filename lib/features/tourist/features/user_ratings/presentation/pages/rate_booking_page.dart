import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/user_ratings/presentation/cubit/user_ratings_cubit.dart';
import 'package:toury/features/tourist/features/user_ratings/presentation/cubit/user_ratings_state.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/di/injection_container.dart';

class RateBookingPage extends StatefulWidget {
  final String bookingId;

  const RateBookingPage({super.key, required this.bookingId});

  @override
  State<RateBookingPage> createState() => _RateBookingPageState();
}

class _RateBookingPageState extends State<RateBookingPage> {
  int _stars = 5;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Friendly',
    'Professional',
    'Knowledgeable',
    'Punctual',
    'Great Tips',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserRatingsCubit>(),
      child: BlocListener<UserRatingsCubit, UserRatingsState>(
        listener: (context, state) {
          if (state is RatingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you for your feedback!')),
            );
            context.go('/home');
          } else if (state is RatingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.errorColor,
              ),
            );
          }
        },
        child: PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Rate your Trip'),
              automaticallyImplyLeading: false,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.spaceXL),
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 48,
                        ),
                        onPressed: () => setState(() => _stars = index + 1),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space2XL),
                  const Text(
                    'What stood out?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppTheme.space2XL),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Share more details about your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space2XL),
                  BlocBuilder<UserRatingsCubit, UserRatingsState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Submit Feedback',
                        isLoading: state is RatingLoading,
                        onPressed: () {
                          context.read<UserRatingsCubit>().submitRating(
                            bookingId: widget.bookingId,
                            stars: _stars,
                            comment: _commentController.text.trim(),
                            tags: _selectedTags,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
