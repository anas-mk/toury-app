import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../helper_bookings/presentation/cubit/helper_bookings_cubits.dart';
import '../../../helper_bookings/presentation/widgets/shared/empty_state_view.dart';
import '../../../helper_bookings/presentation/widgets/shared/skeleton_booking_card.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  late final UpcomingBookingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<UpcomingBookingsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Messages'),
          actions: [
            IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          ],
        ),
        body: BlocBuilder<UpcomingBookingsCubit, UpcomingBookingsState>(
          builder: (context, state) {
            if (state is UpcomingBookingsLoading) {
              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                itemCount: 5,
                itemBuilder: (_, __) => const _ConversationSkeleton(),
              );
            }
            if (state is UpcomingBookingsLoaded) {
              if (state.bookings.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No conversations',
                  subtitle: 'Active chats will appear here after you accept a booking.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _cubit.load(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceSM),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    return _ConversationTile(
                      name: booking.travelerName,
                      lastMsg: 'Click to open chat with traveler...',
                      time: 'Active',
                      unread: 0,
                      onTap: () => context.push('/helper/active-booking', extra: booking.id),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceSM),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColor.primaryColor.withOpacity(0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColor.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(time, style: theme.textTheme.bodySmall),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                ),
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColor.primaryColor, shape: BoxShape.circle),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final skeletonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG, vertical: 12),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: skeletonColor, shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 14, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
