import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/helper_ratings_cubits.dart';
import '../widgets/rating_widgets.dart';

class RateUserPage extends StatefulWidget {
  final String bookingId;
  final String travelerName;
  final String travelerAvatar;

  const RateUserPage({
    super.key,
    required this.bookingId,
    required this.travelerName,
    required this.travelerAvatar,
  });

  @override
  State<RateUserPage> createState() => _RateUserPageState();
}

class _RateUserPageState extends State<RateUserPage> {
  late final RateUserCubit _cubit;
  double _rating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _commentController = TextEditingController();

  final List<String> _availableTags = [
    'Friendly',
    'Respectful',
    'Punctual',
    'Easy to communicate',
    'Generous',
    'Recommended',
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<RateUserCubit>();
  }

  @override
  void dispose() {
    _cubit.close();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        if (_selectedTags.length < 10) {
          _selectedTags.add(tag);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<RateUserCubit, RateUserState>(
        listener: (context, state) {
          if (state is RateUserSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rating submitted successfully!')),
            );
            Navigator.pop(context, true);
          } else if (state is RateUserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Rate Traveler'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.travelerAvatar.isNotEmpty ? NetworkImage(widget.travelerAvatar) : null,
                  backgroundColor: AppColor.primaryColor.withOpacity(0.1),
                  child: widget.travelerAvatar.isEmpty
                      ? Text(widget.travelerName[0], style: const TextStyle(fontSize: 32, color: AppColor.primaryColor))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.travelerName,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'How was your experience with this traveler?',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                StarSelector(
                  rating: _rating,
                  onRatingChanged: (val) => setState(() => _rating = val),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Tags',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTags.map((tag) {
                    return TagChip(
                      label: tag,
                      isSelected: _selectedTags.contains(tag),
                      onTap: () => _toggleTag(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional Comments',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 1000,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Share more details about your experience...',
                    hintStyle: TextStyle(color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                BlocBuilder<RateUserCubit, RateUserState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_rating > 0 && state is! RateUserSubmitting)
                            ? () {
                                _cubit.submitRating(
                                  bookingId: widget.bookingId,
                                  stars: _rating,
                                  comment: _commentController.text,
                                  tags: _selectedTags,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          disabledBackgroundColor: theme.disabledColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: state is RateUserSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit Rating',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
