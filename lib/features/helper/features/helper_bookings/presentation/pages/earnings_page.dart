import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_earnings_entities.dart';
import '../cubit/helper_bookings_cubits.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late final EarningsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EarningsCubit>();
    _cubit.load();
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
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Earnings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: BlocBuilder<EarningsCubit, EarningsState>(
          builder: (context, state) {
            if (state is EarningsLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            if (state is EarningsError) {
              return _buildError(state.message);
            }
            if (state is EarningsLoaded) {
              return _buildContent(state.earnings);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(HelperEarnings e) {
    return RefreshIndicator(
      onRefresh: () async => _cubit.load(),
      color: const Color(0xFF6C63FF),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _HeroCard(earnings: e),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _PCard(
                      label: 'This Week',
                      amount: e.week,
                      color: const Color(0xFF6C63FF))),
              const SizedBox(width: 12),
              Expanded(
                  child: _PCard(
                      label: 'This Month',
                      amount: e.month,
                      color: const Color(0xFFFFAB40))),
            ],
          ),
          const SizedBox(height: 14),
          _StatsCard(trips: e.completedTrips),
          const SizedBox(height: 20),
          if (e.chartData.isNotEmpty) ...[
            const Text('Weekly Overview',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _BarChart(data: e.chartData),
            const SizedBox(height: 20),
          ],
          const Text('Recent Transactions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (e.recentEarnings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: Colors.white24, size: 48),
                    SizedBox(height: 8),
                    Text('No transactions yet',
                        style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            )
          else
            ...e.recentEarnings.map((item) => _TransactionTile(item: item)),
        ],
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFFF6B6B), size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Could not load earnings',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: Colors.white38),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _cubit.load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Earnings Card ────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final HelperEarnings earnings;
  const _HeroCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF007A5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Earnings",
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('\$${earnings.today.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  height: 1.1)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('${earnings.completedTrips} trips completed',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _PCard(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Text('\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int trips;
  const _StatsCard({required this.trips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: Color(0xFF6C63FF), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$trips',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Text('Total Completed Trips',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxV = data.fold(0.0, (p, d) => d.value > p ? d.value : p);
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final frac = maxV > 0 ? d.value / maxV : 0.0;
          final barH = frac * 90;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('\$${d.value.toStringAsFixed(0)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 9)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                width: 22,
                height: barH.clamp(4.0, 90.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00C896)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(d.label,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final EarningItem item;
  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_rounded,
                color: Color(0xFF00C896), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.travelerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(
                  '${item.date.day}/${item.date.month}/${item.date.year}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '+\$${item.amount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
        ],
      ),
    );
  }
}
