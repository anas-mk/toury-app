import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../features/helper/features/profile/presentation/cubit/profile_cubit.dart';
import '../../../../../../features/helper/features/profile/presentation/cubit/profile_state.dart';
import '../../../profile/presentation/widgets/car/car_management_card.dart';
import '../../../profile/presentation/widgets/certificates/certificates_list.dart';
import '../../../profile/presentation/widgets/documents/documents_checklist.dart';
import '../../../profile/presentation/widgets/eligibility/eligibility_alert.dart';
import '../../../profile/presentation/widgets/header/helper_profile_header.dart';
import '../../../profile/presentation/widgets/images/image_management_card.dart';
import '../../../profile/presentation/widgets/onboarding/onboarding_progress_card.dart';
import '../../../profile/presentation/widgets/profile_info/profile_info_form.dart';
import '../../../profile/presentation/widgets/status/profile_status_card.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // We provide the Cubit directly if it's not provided above, but assuming 
  // standard routing, we'll wrap it here to ensure independence as requested.
  // ProfileCubit cubit is factory registered.
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (context) => sl<ProfileCubit>()..fetchProfileBundle(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) => previous.successMessage != current.successMessage || previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
              );
              context.read<ProfileCubit>().clearMessages();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
              context.read<ProfileCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            if (state.status == ProfileStatus.initial || (state.status == ProfileStatus.loading && state.profile == null)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.profile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: AppTheme.spaceMD),
                    const Text('Failed to load profile.'),
                    const SizedBox(height: AppTheme.spaceSM),
                    ElevatedButton(
                      onPressed: () => context.read<ProfileCubit>().fetchProfileBundle(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final profile = state.profile!;
            final eligibilityRecord = state.eligibilityRecord;
            final statusRecord = state.statusRecord;

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ProfileCubit>().fetchProfileBundle();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                children: [
                  const SizedBox(height: AppTheme.spaceXL),
                  HelperProfileHeader(profile: profile),
                  const SizedBox(height: AppTheme.spaceLG),
                  
                  // Basic Info Edit Trigger
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => ProfileInfoForm.show(context, profile),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Basic Info'),
                    ),
                  ),

                  if (eligibilityRecord != null && !eligibilityRecord.isEligible) ...[
                    EligibilityAlert(eligibility: eligibilityRecord),
                    const SizedBox(height: AppTheme.spaceMD),
                  ],
                  
                  OnboardingProgressCard(profile: profile),
                  const SizedBox(height: AppTheme.spaceMD),

                  if (statusRecord != null) ...[
                    ProfileStatusCard(
                      status: statusRecord,
                      onSubmitForReview: () {
                        // TODO: Implement submission when the Submit for Review API is ready
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                  ],

                  ImageManagementCard(profile: profile),
                  const SizedBox(height: AppTheme.spaceMD),

                  const DocumentsChecklist(),
                  const SizedBox(height: AppTheme.spaceMD),

                  CarManagementCard(car: profile.car),
                  const SizedBox(height: AppTheme.spaceMD),

                  CertificatesList(certificates: profile.certificates),
                  const SizedBox(height: AppTheme.spaceXL * 2), // Bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
