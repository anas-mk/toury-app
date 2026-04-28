import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../../core/theme/app_theme.dart';

class DocumentPickerWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final XFile? file;
  final VoidCallback onPickPressed;
  final VoidCallback onRemovePressed;

  const DocumentPickerWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.file,
    required this.onPickPressed,
    required this.onRemovePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (file != null) ...[
              const SizedBox(width: AppTheme.spaceSM),
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spaceMD),
        GestureDetector(
          onTap: file == null ? onPickPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(
                color: file != null ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.1),
                width: file != null ? 2 : 1,
              ),
            ),
            child: file != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG - 2),
                        child: Image.file(
                          File(file!.path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black.withOpacity(0.6),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: onRemovePressed,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceMD),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMD),
                      Text(
                        'Tap to Upload',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
