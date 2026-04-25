import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1120),
          elevation: 0,
          title: const Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white38), onPressed: () {}),
          ],
        ),
        body: BlocBuilder<UpcomingBookingsCubit, UpcomingBookingsState>(
          builder: (context, state) {
            if (state is UpcomingBookingsLoading) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.all(8),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = state.bookings[index];
                    return _ConversationTile(
                      name: booking.travelerName,
                      lastMsg: 'Click to open chat with traveler...',
                      time: 'Active',
                      unread: 0,
                      onTap: () => context.push('/helper/active-booking', extra: booking.id), // Redirect to chat/active page
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
