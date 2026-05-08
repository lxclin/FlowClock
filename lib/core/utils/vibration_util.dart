import 'package:flutter/services.dart';

class VibrationUtil {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void timerComplete() {
    heavy();
    Future.delayed(const Duration(milliseconds: 200), heavy);
    Future.delayed(const Duration(milliseconds: 400), heavy);
  }
}
