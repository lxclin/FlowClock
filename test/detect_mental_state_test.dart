import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pomodoro/biometrics/models/mental_state.dart';
import 'package:flutter_pomodoro/biometrics/models/biometric_baseline.dart';
import 'package:flutter_pomodoro/biometrics/models/biometric_snapshot.dart';
import 'package:flutter_pomodoro/biometrics/services/detect_mental_state.dart';

void main() {
  final baseline = BiometricBaseline(
    restingHr: 65.0,
    restingHrvRmssd: 42.0,
    restingHrvSdnn: 53.0,
    hrvRmssdStd: 8.0,
    calibratedAt: DateTime(2024, 1, 1),
  );

  group('detectMentalState', () {
    test('returns normal when session history is insufficient (< 2 readings)', () {
      final current = BiometricSnapshot(
        hr: 65.0,
        hrvRmssd: 42.0,
        hrvSdnn: 53.0,
        timestamp: DateTime.now(),
      );

      final result = detectMentalState(current, baseline, []);
      expect(result.state, MentalState.normal);

      final result2 = detectMentalState(current, baseline, [current]);
      expect(result2.state, MentalState.normal);
    });

    test('returns normal for typical resting reading', () {
      final readings = List.generate(
        6,
        (_) => BiometricSnapshot(
          hr: 65.0,
          hrvRmssd: 42.0,
          hrvSdnn: 53.0,
          timestamp: DateTime.now(),
        ),
      );

      final current = BiometricSnapshot(
        hr: 66.0,
        hrvRmssd: 41.0,
        hrvSdnn: 52.0,
        timestamp: DateTime.now(),
      );

      final result = detectMentalState(current, baseline, readings);
      expect(result.state, MentalState.normal);
    });

    test('detects flow when HR mildly elevated and HRV stable', () {
      final readings = List.generate(
        6,
        (_) => BiometricSnapshot(
          hr: 70.0,
          hrvRmssd: 44.0,
          hrvSdnn: 55.0,
          timestamp: DateTime.now(),
        ),
      );

      final current = BiometricSnapshot(
        hr: 72.0,
        hrvRmssd: 43.0,
        hrvSdnn: 54.0,
        timestamp: DateTime.now(),
      );

      final result = detectMentalState(current, baseline, readings);
      expect(result.state, MentalState.flow);
      expect(result.hrInFlowZone, true);
      expect(result.hrvStable, true);
    });

    test('detects fatigue when HRV collapses and HR abnormal', () {
      final readings = List.generate(
        6,
        (_) => BiometricSnapshot(
          hr: 75.0,
          hrvRmssd: 25.0,
          hrvSdnn: 30.0,
          timestamp: DateTime.now(),
        ),
      );

      final current = BiometricSnapshot(
        hr: 80.0,
        hrvRmssd: 20.0,
        hrvSdnn: 28.0,
        timestamp: DateTime.now(),
      );

      final result = detectMentalState(current, baseline, readings);
      expect(result.state, MentalState.fatigue);
      expect(result.hrvCollapse, true);
      expect(result.hrAbnormal, true);
    });

    test('returns normal when HRV collapses but HR is normal', () {
      final readings = List.generate(
        6,
        (_) => BiometricSnapshot(
          hr: 65.0,
          hrvRmssd: 28.0,
          hrvSdnn: 35.0,
          timestamp: DateTime.now(),
        ),
      );

      final current = BiometricSnapshot(
        hr: 66.0,
        hrvRmssd: 25.0,
        hrvSdnn: 32.0,
        timestamp: DateTime.now(),
      );

      final result = detectMentalState(current, baseline, readings);
      expect(result.state, MentalState.normal);
    });

    test('fatigue takes priority over flow', () {
      final readings = List.generate(
        6,
        (_) => BiometricSnapshot(
          hr: 75.0,
          hrvRmssd: 25.0,
          hrvSdnn: 30.0,
          timestamp: DateTime.now(),
        ),
      );

      final current = BiometricSnapshot(
        hr: 80.0,
        hrvRmssd: 20.0,
        hrvSdnn: 28.0,
        timestamp: DateTime.now(),
      );

      final result = detectMentalState(current, baseline, readings);
      expect(result.state, MentalState.fatigue);
    });
  });
}

