import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../cubit/user_ratings_cubit.dart';
import '../cubit/user_ratings_state.dart';

class RatingBottomSheet extends StatefulWidget {
  final String bookingId;
  final String helperName;

  const RatingBottomSheet({
    super.key,
    required this.bookingId,
    required this.helperName,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  int _selectedStars = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Punctual',
    'Friendly',
    'Knowledgeable',
    'Professional',
    'Great Car',
    'Safe Driver',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: BlocConsumer<UserRatingsCubit, UserRatingsState>(
        listener: (context, state) {
          if (state is UserRatingsSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you for your rating!')),
            );
            Navigator.pop(context, true);
          } else if (state is UserRatingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Rate your trip with ${widget.helperName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your feedback helps us maintain high service quality.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildStarSelector(),
              const SizedBox(height: 32),
              if (_selectedStars > 0) ...[
                _buildTagSelector(),
                const SizedBox(height: 24),
                _buildCommentField(),
                const SizedBox(height: 32),
              ],
              CustomButton(
                text: 'Submit Rating',
                isLoading: state is UserRatingsSubmitting,
                onPressed: _selectedStars == 0
                    ? null
                    : () {
                        context.read<UserRatingsCubit>().rateHelper(
                              bookingId: widget.bookingId,
                              stars: _selectedStars,
                              comment: _commentController.text,
                              tags: _selectedTags,
                            );
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _selectedStars;
        return GestureDetector(
          onTap: () => setState(() => _selectedStars = starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 48,
              color: isSelected ? Colors.amber : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WHAT WENT WELL?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColor.primaryColor : Colors.transparent,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Share more about your experience (optional)',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
