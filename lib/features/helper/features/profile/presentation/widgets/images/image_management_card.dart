import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../domain/entities/helper_profile_entity.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import '../../utils/profile_image_helper.dart';

class ImageManagementCard extends StatelessWidget {
  final HelperProfileEntity profile;

  const ImageManagementCard({super.key, required this.profile});

  Future<void> _pickAndUpload(BuildContext context, bool isSelfie) async {
    try {
      final file = await ProfileImageHelper.pickAndValidateImage(ImageSource.gallery);
      if (file == null) return;
      
      if (!context.mounted) return;

      if (isSelfie) {
        context.read<ProfileCubit>().uploadSelfie(file);
      } else {
        context.read<ProfileCubit>().uploadProfileImage(file);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      variant: CardVariant.elevated,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isUploadingImage = state.status == ProfileStatus.uploadingImage;
          final isUploadingSelfie = state.status == ProfileStatus.uploadingSelfie;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity Verification',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Row(
                children: [
                  Expanded(
                    child: _ImageUploadBox(
                      title: 'Profile Photo',
                      imageUrl: profile.profileImageUrl,
                      isLoading: isUploadingImage,
                      onTap: () => _pickAndUpload(context, false),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: _ImageUploadBox(
                      title: 'Selfie',
                      imageUrl: profile.selfieImageUrl,
                      isLoading: isUploadingSelfie,
                      onTap: () => _pickAndUpload(context, true),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _ImageUploadBox({
    required this.title,
    required this.imageUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: hasImage ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
              image: hasImage && !isLoading
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : (!hasImage
                      ? Icon(Icons.add_a_photo, color: Colors.grey[400], size: 32)
                      : null),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
