import 'package:flutter/material.dart';

class AppNavigator {

  static void pushReplacement(BuildContext context,Widget widget) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget)
    );
  }

  static void pushReplacementUntil(BuildContext context,Widget widget) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => widget),
        (route) => false,
    );
  }

  static void push(BuildContext context,Widget widget) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget)
    );
  }

  static void pushAndRemove(BuildContext context,Widget widget) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => widget),
      (Route<dynamic> route) => false
    );
  }
}