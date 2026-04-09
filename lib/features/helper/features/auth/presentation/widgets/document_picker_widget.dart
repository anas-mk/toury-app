import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../../core/theme/app_color.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: file == null ? onPickPressed : null,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: file != null ? AppColor.primaryColor : Colors.grey[400]!,
                width: file != null ? 2 : 1,
                style: file != null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: file != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
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
                        child: GestureDetector(
                          onTap: onRemovePressed,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload file',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
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
