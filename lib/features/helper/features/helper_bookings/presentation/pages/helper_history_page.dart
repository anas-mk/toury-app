import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';

class HelperHistoryPage extends StatefulWidget {
  const HelperHistoryPage({super.key});

  @override
  State<HelperHistoryPage> createState() => _HelperHistoryPageState();
}

class _HelperHistoryPageState extends State<HelperHistoryPage>
    with SingleTickerProviderStateMixin {
  late final HelperHistoryCubit _cubit;
  late TabController _tab;
  final ScrollController _scroll = ScrollController();
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _cubit = sl<HelperHistoryCubit>();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        _cubit.load(
          status: _tab.index == 0 ? 'completed' : 'cancelled',
          from: _from,
          to: _to,
        );
      }
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        _cubit.loadMore();
      }
    });
    _cubit.load(status: 'completed');
  }

  @override
  void dispose() {
    _tab.dispose();
    _scroll.dispose();
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
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filter',
              onPressed: () => _showFilter(context),
            ),
          ],
          bottom: TabBar(
            controller: _tab,
            indicatorColor: const Color(0xFF6C63FF),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.white38,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: '✅  Completed'),
              Tab(text: '❌  Cancelled'),
            ],
          ),
        ),
        body: BlocBuilder<HelperHistoryCubit, HelperHistoryState>(
          builder: (context, state) {
            if (state is HelperHistoryLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            if (state is HelperHistoryError) {
              return _buildError(state.message);
            }
            if (state is HelperHistoryLoaded) {
              final completed = state.bookings
                  .where((b) => b.status == 'completed')
                  .toList();
              final cancelled = state.bookings
                  .where((b) => b.status == 'cancelled')
                  .toList();
              return TabBarView(
                controller: _tab,
                children: [
                  _HistoryList(
                    bookings: completed,
                    scrollCtrl: _scroll,
                    hasMore: state.hasMore,
                    onRefresh: () => _cubit.load(
                        status: 'completed', from: _from, to: _to),
                  ),
                  _HistoryList(
                    bookings: cancelled,
                    scrollCtrl: _scroll,
                    hasMore: false,
                    onRefresh: () => _cubit.load(
                        status: 'cancelled', from: _from, to: _to),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded,
                color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text('Could not load history',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: Colors.white38),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () =>
                  _cubit.load(status: 'completed', from: _from, to: _to),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    DateTime? tempFrom = _from;
    DateTime? tempTo = _to;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Filter by Date',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'From',
                      date: tempFrom,
                      onPick: (d) => set(() => tempFrom = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      label: 'To',
                      date: tempTo,
                      onPick: (d) => set(() => tempTo = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _from = null;
                          _to = null;
                        });
                        _cubit.load(
                            status:
                                _tab.index == 0 ? 'completed' : 'cancelled');
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white38,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _from = tempFrom;
                          _to = tempTo;
                        });
                        _cubit.load(
                          status:
                              _tab.index == 0 ? 'completed' : 'cancelled',
                          from: _from,
                          to: _to,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Apply',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<HelperBooking> bookings;
  final ScrollController scrollCtrl;
  final bool hasMore;
  final VoidCallback onRefresh;
  const _HistoryList(
      {required this.bookings,
      required this.scrollCtrl,
      required this.hasMore,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 56),
            SizedBox(height: 16),
            Text('No records',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF6C63FF),
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: bookings.length + (hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == bookings.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child:
                  Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            );
          }
          return _HistoryCard(booking: bookings[i]);
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HelperBooking booking;
  const _HistoryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final done = booking.status == 'completed';
    final accent = done ? const Color(0xFF00C896) : const Color(0xFFFF6B6B);
    return GestureDetector(
      onTap: () => context.push('/helper-booking-details/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.close_rounded,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.travelerName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(booking.destinationLocation,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_fmt(booking.startTime),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Text('\$${booking.payout.toStringAsFixed(0)}',
                style: TextStyle(
                    color: done ? const Color(0xFF00C896) : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;
  const _DateTile(
      {required this.label, this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF6C63FF)),
            ),
            child: child!,
          ),
        );
        onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : 'Select',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
