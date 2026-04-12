import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageHelper {
  static final ImagePicker _picker = ImagePicker();
  static const int _maxSizeInBytes = 5 * 1024 * 1024; // 5 MB

  /// Picks an image and performs compression.
  /// Validates file size against < 5MB rule.
  /// Throws an exception with a user-friendly message if validation fails.
  static Future<File?> pickAndValidateImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Built-in compression
      maxWidth: 1200, // Limit resolution to reduce size
      maxHeight: 1200,
    );

    if (pickedFile == null) return null;

    final File file = File(pickedFile.path);
    final int sizeInBytes = await file.length();

    if (sizeInBytes > _maxSizeInBytes) {
      throw const FormatException('Image size exceeds 5MB limit. Please choose a smaller file.');
    }

    return file;
  }
}
