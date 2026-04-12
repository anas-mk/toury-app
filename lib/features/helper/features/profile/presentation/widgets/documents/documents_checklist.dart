import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/custom_card.dart';
import '../../../../../../../core/widgets/custom_button.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import '../../utils/profile_image_helper.dart';

class DocumentsChecklist extends StatefulWidget {
  const DocumentsChecklist({super.key});

  @override
  State<DocumentsChecklist> createState() => _DocumentsChecklistState();
}

class _DocumentsChecklistState extends State<DocumentsChecklist> {
  File? _nationalIdFront;
  File? _nationalIdBack;
  File? _criminalRecord;
  File? _drugTest;

  bool get _canSubmit => _nationalIdFront != null && _nationalIdBack != null;

  Future<void> _pickDocument(String type) async {
    try {
      final file = await ProfileImageHelper.pickAndValidateImage(ImageSource.gallery);
      if (file == null) return;
      
      setState(() {
        switch (type) {
          case 'id_front': _nationalIdFront = file; break;
          case 'id_back': _nationalIdBack = file; break;
          case 'criminal': _criminalRecord = file; break;
          case 'drug': _drugTest = file; break;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _submit() {
    if (!_canSubmit) return;
    context.read<ProfileCubit>().uploadDocuments(
      nationalIdFront: _nationalIdFront!,
      nationalIdBack: _nationalIdBack!,
      criminalRecord: _criminalRecord,
      drugTest: _drugTest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If documents are not empty in profile, ideally we'd show a "Verified" state.
    // Assuming we just provide the upload UI here for simplicity and requirements.

    return CustomCard(
      variant: CardVariant.elevated,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isLoading = state.status == ProfileStatus.uploadingDocuments;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Documents (Batch Upload)',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'You must upload both sides of your National ID to proceed.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppTheme.spaceMD),

              _DocItem(
                title: 'National ID (Front) *',
                file: _nationalIdFront,
                onTap: isLoading ? null : () => _pickDocument('id_front'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _DocItem(
                title: 'National ID (Back) *',
                file: _nationalIdBack,
                onTap: isLoading ? null : () => _pickDocument('id_back'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _DocItem(
                title: 'Criminal Record (Optional)',
                file: _criminalRecord,
                onTap: isLoading ? null : () => _pickDocument('criminal'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _DocItem(
                title: 'Drug Test (Optional)',
                file: _drugTest,
                onTap: isLoading ? null : () => _pickDocument('drug'),
              ),

              const SizedBox(height: AppTheme.spaceLG),
              CustomButton(
                text: 'Upload Documents',
                onPressed: _canSubmit ? _submit : null,
                isLoading: isLoading,
                isFullWidth: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String title;
  final File? file;
  final VoidCallback? onTap;

  const _DocItem({required this.title, this.file, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = file != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.green : Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          color: isSelected ? Colors.green.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.upload_file,
              color: isSelected ? Colors.green : theme.colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: Text(
                isSelected ? 'Selected: ${file!.path.split('/').last}' : title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.green[700] : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
