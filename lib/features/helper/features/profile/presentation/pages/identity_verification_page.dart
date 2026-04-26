import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Identity & Documents'),
        elevation: 0,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final statusRecord = state.statusRecord;
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            children: [
              if (statusRecord != null) ...[
                ProfileStatusCard(
                  status: statusRecord,
                  onSubmitForReview: () {},
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Document Checklist',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const DocumentsChecklist(),
              const SizedBox(height: 32),
              Text(
                'Verification Status',
                style: TextStyle(
                  color: isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary,
                  fontSize: 13,
                ),
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isVerified ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              color: isVerified ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
