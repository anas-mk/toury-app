import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../cubit/helper_ratings_cubits.dart';
import 'rating_widgets.dart';

/// Loads eligibility (same rules as the old bottom sheet), then opens
/// [showRateTravelerDialog] when allowed — **no bottom sheet**.
Future<void> openRateTravelerForBooking(
  BuildContext context, {
  required String bookingId,
  required String travelerName,
  required String travelerAvatar,
}) async {
  final cubit = sl<BookingRatingStateCubit>();
  try {
    await cubit.loadState(bookingId);
    if (!context.mounted) return;
    final state = cubit.state;
    if (state is BookingRatingLoaded) {
      final s = state.stateEntity;
      if (s.canRate) {
        await showRateTravelerDialog(
          context,
          bookingId: bookingId,
          travelerName: travelerName,
          travelerAvatar: travelerAvatar,
        );
      } else if (s.callerHasRated) {
        AppSnackbar.info(context, 'You have already rated this traveler.');
      } else {
        AppSnackbar.info(
          context,
          'You can rate the traveler after the trip is marked as completed.',
        );
      }
    } else if (state is BookingRatingError) {
      AppSnackbar.error(context, state.message);
    }
  } finally {
    await cubit.close();
  }
}

/// Full-screen-style rating flow in a dialog (replaces pushing [RateUserPage]).
Future<bool?> showRateTravelerDialog(
  BuildContext context, {
  required String bookingId,
  required String travelerName,
  required String travelerAvatar,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final maxH = MediaQuery.sizeOf(dialogContext).height * 0.88;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH, maxWidth: 420),
          child: _RateTravelerDialogBody(
            bookingId: bookingId,
            travelerName: travelerName,
            travelerAvatar: travelerAvatar,
          ),
        ),
      );
    },
  );
}

class _RateTravelerDialogBody extends StatefulWidget {
  final String bookingId;
  final String travelerName;
  final String travelerAvatar;

  const _RateTravelerDialogBody({
    required this.bookingId,
    required this.travelerName,
    required this.travelerAvatar,
  });

  @override
  State<_RateTravelerDialogBody> createState() => _RateTravelerDialogBodyState();
}

class _RateTravelerDialogBodyState extends State<_RateTravelerDialogBody> {
  static const String _imageHost = 'https://tourestaapi.runasp.net';

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

  String get _avatarUrl {
    final raw = widget.travelerAvatar;
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return '$_imageHost$raw';
  }

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
    final resolvedAvatar = _avatarUrl;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<RateUserCubit, RateUserState>(
        listener: (context, state) {
          if (state is RateUserSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rating submitted successfully!')),
            );
            Navigator.of(context).pop(true);
          } else if (state is RateUserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.errorColor,
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rate Traveler',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: resolvedAvatar.isNotEmpty
                          ? NetworkImage(resolvedAvatar)
                          : null,
                      backgroundColor: AppColor.primaryColor.withValues(alpha: 0.1),
                      child: resolvedAvatar.isEmpty
                          ? Text(
                              widget.travelerName.isNotEmpty
                                  ? widget.travelerName[0]
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                color: AppColor.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.travelerName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'How was your experience with this traveler?',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    StarSelector(
                      rating: _rating,
                      onRatingChanged: (val) => setState(() => _rating = val),
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Tags',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Additional Comments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColor.darkTextSecondary
                              : AppColor.lightTextSecondary,
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<RateUserCubit, RateUserState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_rating > 0 &&
                                    state is! RateUserSubmitting)
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
                              disabledBackgroundColor:
                                  theme.disabledColor.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: state is RateUserSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit Rating',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
