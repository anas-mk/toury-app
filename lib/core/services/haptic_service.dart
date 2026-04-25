import 'package:flutter/services.dart';

class HapticService {
  static Future<void> light() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }
}
