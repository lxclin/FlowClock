import 'dart:math';
import '../models/mental_state.dart';
import '../models/biometric_baseline.dart';
import '../models/biometric_snapshot.dart';

class MentalStateResult {
  final MentalState state;
  final double hrDeviationPct;
  final double rmssdZScore;
  final bool hrvCollapse;
  final bool hrAbnormal;
  final bool hrInFlowZone;
  final bool hrvStable;
  final bool hrvNotDeclining;

  const MentalStateResult({
    required this.state,
    required this.hrDeviationPct,
    required this.rmssdZScore,
    required this.hrvCollapse,
    required this.hrAbnormal,
    required this.hrInFlowZone,
    required this.hrvStable,
    required this.hrvNotDeclining,
  });
}

MentalStateResult detectMentalState(
  BiometricSnapshot current,
  BiometricBaseline baseline,
  List<BiometricSnapshot> sessionHistory,
) {
  final hrDeviationPct =
      (current.hr - baseline.restingHr) / baseline.restingHr * 100.0;

  final rmssdZScore =
      (current.hrvRmssd - baseline.restingHrvRmssd) / baseline.hrvRmssdStd;

  final hrvCollapse =
      current.hrvRmssd < (baseline.restingHrvRmssd * 0.70);

  final hrAbnormal = hrDeviationPct > 20 || hrDeviationPct < -15;

  final hrInFlowZone = hrDeviationPct >= 5 && hrDeviationPct <= 15;

  final hrvStable = rmssdZScore > -0.5;

  double rollingRmssdStd = 0.0;
  if (sessionHistory.length >= 2) {
    final window = sessionHistory.length >= 4
        ? sessionHistory.sublist(sessionHistory.length - 4)
        : sessionHistory;
    final values = window.map((s) => s.hrvRmssd).toList();
    rollingRmssdStd = _stddev(values);
  }

  final hrvNotDeclining =
      rollingRmssdStd < (baseline.restingHrvRmssd * 0.15);

  MentalState state;
  if (hrvCollapse && hrAbnormal) {
    state = MentalState.fatigue;
  } else if (hrInFlowZone && hrvStable && hrvNotDeclining) {
    state = MentalState.flow;
  } else {
    state = MentalState.normal;
  }

  return MentalStateResult(
    state: state,
    hrDeviationPct: hrDeviationPct,
    rmssdZScore: rmssdZScore,
    hrvCollapse: hrvCollapse,
    hrAbnormal: hrAbnormal,
    hrInFlowZone: hrInFlowZone,
    hrvStable: hrvStable,
    hrvNotDeclining: hrvNotDeclining,
  );
}

double _stddev(List<double> values) {
  if (values.isEmpty) return 0.0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final squaredDiffs =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
  return sqrt(squaredDiffs / values.length);
}
