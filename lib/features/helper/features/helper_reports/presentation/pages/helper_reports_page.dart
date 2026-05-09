import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/helper_reports_cubit.dart';
import '../../domain/entities/helper_report_entities.dart';

class HelperReportsPage extends StatelessWidget {
  const HelperReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1120),
        elevation: 0,
        title: const Text('Reports & Support', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<HelperReportsCubit, HelperReportsState>(
        builder: (context, state) {
          if (state is HelperReportsInitial) {
            context.read<HelperReportsCubit>().loadReports();
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (state is HelperReportsLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (state is HelperReportsLoaded) {
            if (state.reports.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () => context.read<HelperReportsCubit>().loadReports(),
              child: _buildReportList(state.reports),
            );
          }
          if (state is HelperReportsError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.white70)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          const Text('No reports found', style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildReportList(List<HelperReportEntity> reports) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final report = reports[index];
        return _ReportCard(report: report);
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final HelperReportEntity report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: report.isResolved 
              ? const Color(0xFF00C896).withValues(alpha: 0.2) 
              : const Color(0xFFFFAB40).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  report.reason,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _StatusBadge(isResolved: report.isResolved),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.details,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (report.isResolved && report.resolutionNote != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resolution Note:', style: TextStyle(color: Color(0xFF00C896), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(report.resolutionNote!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(report.createdAt),
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              if (report.isResolved && report.resolvedAt != null)
                Text(
                  'Resolved on ${DateFormat('MMM dd').format(report.resolvedAt!)}',
                  style: const TextStyle(color: Color(0xFF00C896), fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isResolved;
  const _StatusBadge({required this.isResolved});

  @override
  Widget build(BuildContext context) {
    final color = isResolved ? const Color(0xFF00C896) : const Color(0xFFFFAB40);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isResolved ? 'RESOLVED' : 'PENDING',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
