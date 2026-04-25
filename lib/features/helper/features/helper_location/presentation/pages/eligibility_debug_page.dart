import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/location_status_cubits.dart';

class EligibilityDebugPage extends StatefulWidget {
  const EligibilityDebugPage({super.key});

  @override
  State<EligibilityDebugPage> createState() => _EligibilityDebugPageState();
}

class _EligibilityDebugPageState extends State<EligibilityDebugPage> {
  late final EligibilityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EligibilityCubit>();
    _cubit.loadEligibility();
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
          title: const Text('Eligibility Debug', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _cubit.loadEligibility(),
            ),
          ],
        ),
        body: BlocBuilder<EligibilityCubit, EligibilityState>(
          builder: (context, state) {
            if (state is EligibilityLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            if (state is EligibilityError) {
              return _buildError(state.message);
            }
            if (state is EligibilityLoaded) {
              return _buildContent(state.eligibility);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(dynamic eligibility) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StatusHeader(isEligible: eligibility.isEligible),
        const SizedBox(height: 24),
        const Text('Exclusion Reasons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (eligibility.warnings.isEmpty)
          const Text('No exclusion reasons found. Helper is fully eligible.', style: TextStyle(color: Colors.white38, fontSize: 14))
        else
          ...eligibility.warnings.map((w) => _WarningCard(warning: w)),
        const SizedBox(height: 24),
        const Text('Debug Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _DebugInfoGrid(info: eligibility.debugInfo),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 48),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _cubit.loadEligibility(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final bool isEligible;
  const _StatusHeader({required this.isEligible});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isEligible ? const Color(0xFF00C896) : const Color(0xFFFF6B6B)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isEligible ? const Color(0xFF00C896) : const Color(0xFFFF6B6B)).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isEligible ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isEligible ? const Color(0xFF00C896) : const Color(0xFFFF6B6B),
            size: 48,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEligible ? 'Eligible' : 'Not Eligible',
                  style: TextStyle(
                    color: isEligible ? const Color(0xFF00C896) : const Color(0xFFFF6B6B),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isEligible ? 'You are visible to travelers.' : 'Travelers cannot see you.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final dynamic warning;
  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final isCritical = warning.severity == 'critical';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isCritical ? Colors.red : Colors.orange).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical ? Icons.report_problem_rounded : Icons.warning_amber_rounded,
            color: isCritical ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warning.message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Code: ${warning.code}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugInfoGrid extends StatelessWidget {
  final Map<String, dynamic> info;
  const _DebugInfoGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: info.entries.map((e) => _InfoRow(label: e.key, value: e.value.toString())).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
