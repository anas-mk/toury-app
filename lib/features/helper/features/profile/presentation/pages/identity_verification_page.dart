import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/documents/documents_checklist.dart';
import '../widgets/status/profile_status_card.dart';

class IdentityVerificationPage extends StatelessWidget {
  final HelperProfileEntity profile;
  const IdentityVerificationPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1120),
        title: const Text('Identity & Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final statusRecord = state.statusRecord;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (statusRecord != null) ...[
                ProfileStatusCard(
                  status: statusRecord,
                  onSubmitForReview: () {},
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Document Checklist',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const DocumentsChecklist(),
              const SizedBox(height: 32),
              const Text(
                'Verification Status',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _StatusTile(
                label: 'National ID',
                isVerified: profile.isApproved,
              ),
              _StatusTile(
                label: 'Criminal Record',
                isVerified: profile.isApproved,
              ),
              _StatusTile(
                label: 'Drug Test',
                isVerified: profile.isApproved,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final bool isVerified;
  const _StatusTile({required this.label, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isVerified ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(color: isVerified ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
