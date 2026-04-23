import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/helper_ratings_cubit.dart';

class RateUserScreen extends StatefulWidget {
  final String bookingId;

  const RateUserScreen({super.key, required this.bookingId});

  @override
  State<RateUserScreen> createState() => _RateUserScreenState();
}

class _RateUserScreenState extends State<RateUserScreen> {
  int _selectedStars = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Friendly', 'On Time', 'Respectful', 'Good Communication', 'Clean', 'Patient', 'Polite'
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one star')));
      return;
    }
    context.read<HelperRatingsCubit>().submitRating(
      widget.bookingId,
      _selectedStars,
      _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      _selectedTags,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Tourist')),
      body: BlocConsumer<HelperRatingsCubit, HelperRatingsState>(
        listener: (context, state) {
          if (state is RatingsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is RatingsLoaded && !state.isSubmitting) {
            final status = state.bookingStatuses[widget.bookingId];
            if (status?.callerHasRated == true) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted successfully')));
              context.pop();
            }
          }
        },
        builder: (context, state) {
          final isSubmitting = state is RatingsLoaded && state.isSubmitting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How was your experience?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your feedback helps maintain a professional community.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                
                // Star Selector
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 48,
                        icon: Icon(
                          index < _selectedStars ? Icons.star : Icons.star_border,
                          color: index < _selectedStars ? Colors.amber : Colors.grey[300],
                        ),
                        onPressed: isSubmitting ? null : () => setState(() => _selectedStars = index + 1),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),

                // Tags
                const Text('Select tags (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: isSubmitting ? null : (selected) {
                        setState(() {
                          if (selected) {
                            if (_selectedTags.length < 10) _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Comment
                const Text('Add a comment (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Share more details about your trip...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 48),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
