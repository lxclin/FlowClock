import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mental_state.dart';
import '../models/biometric_baseline.dart';
import '../models/biometric_snapshot.dart';
import '../models/biometric_alert.dart';
import '../services/detect_mental_state.dart';
import '../services/biometrics_repository.dart';
import '../services/sensor_adapter.dart';
import '../services/sensor_adapter_mock.dart';
import '../services/health_sensor_adapter.dart';

/// Which data source the biometrics pipeline is using.
enum SensorMode { mock, health }

class BiometricsState {
  final BiometricBaseline? baseline;
  final bool isCalibrated;
  final bool biometricsEnabled;
  final bool isScanning;
  final BiometricSnapshot? latestReading;
  final List<BiometricSnapshot> sessionReadings;
  final MentalState currentMentalState;
  final double? hrDeviationPct;
  final DateTime? lastAlertTime;
  final int flowAlertCount;
  final DateTime? lastFatigueAlertTime;

  /// Active sensor mode — `health` when real hardware is available,
  /// `mock` otherwise.
  final SensorMode sensorMode;

  /// `true` when the device supports health-data hardware and the user has
  /// granted permissions.
  final bool healthAvailable;

  /// Human-readable error when health initialisation fails (e.g. permissions
  /// denied or unsupported device).
  final String? healthError;

  const BiometricsState({
    this.baseline,
    this.isCalibrated = false,
    this.biometricsEnabled = false,
    this.isScanning = false,
    this.latestReading,
    this.sessionReadings = const [],
    this.currentMentalState = MentalState.normal,
    this.hrDeviationPct,
    this.lastAlertTime,
    this.flowAlertCount = 0,
    this.lastFatigueAlertTime,
    this.sensorMode = SensorMode.mock,
    this.healthAvailable = false,
    this.healthError,
  });

  BiometricsState copyWith({
    BiometricBaseline? baseline,
    bool? isCalibrated,
    bool? biometricsEnabled,
    bool? isScanning,
    BiometricSnapshot? latestReading,
    List<BiometricSnapshot>? sessionReadings,
    MentalState? currentMentalState,
    double? hrDeviationPct,
    DateTime? lastAlertTime,
    int? flowAlertCount,
    DateTime? lastFatigueAlertTime,
    SensorMode? sensorMode,
    bool? healthAvailable,
    String? healthError,
    bool clearHealthError = false,
  }) {
    return BiometricsState(
      baseline: baseline ?? this.baseline,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      isScanning: isScanning ?? this.isScanning,
      latestReading: latestReading ?? this.latestReading,
      sessionReadings: sessionReadings ?? this.sessionReadings,
      currentMentalState: currentMentalState ?? this.currentMentalState,
      hrDeviationPct: hrDeviationPct ?? this.hrDeviationPct,
      lastAlertTime: lastAlertTime ?? this.lastAlertTime,
      flowAlertCount: flowAlertCount ?? this.flowAlertCount,
      lastFatigueAlertTime: lastFatigueAlertTime ?? this.lastFatigueAlertTime,
      sensorMode: sensorMode ?? this.sensorMode,
      healthAvailable: healthAvailable ?? this.healthAvailable,
      healthError:
          clearHealthError ? null : (healthError ?? this.healthError),
    );
  }
}

final biometricsProvider =
    StateNotifierProvider<BiometricsNotifier, BiometricsState>((ref) {
  return BiometricsNotifier();
});

class BiometricsNotifier extends StateNotifier<BiometricsState> {
  late final BiometricsRepository _repository;
  SensorAdapter? _sensor;
  StreamSubscription<BiometricSnapshot>? _subscription;
  bool _disposed = false;

  BiometricsNotifier() : super(const BiometricsState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = BiometricsRepository(prefs);
    final baseline = await _repository.getBaseline();
    final calibrated = _repository.isCalibrated;
    final enabled = _repository.biometricsEnabled;

    // Probe whether real health hardware is available.
    // If the probe fails we stay in mock mode silently — the user can still
    // use mock simulation in development or on devices without wearables.
    bool healthOk = false;
    if (enabled) {
      healthOk = await _probeHealthAdapter();
    }

    if (!_disposed) {
      state = state.copyWith(
        baseline: baseline ?? BiometricBaseline.defaults,
        isCalibrated: calibrated,
        biometricsEnabled: enabled,
        healthAvailable: healthOk,
        sensorMode: healthOk ? SensorMode.health : SensorMode.mock,
      );
    }
  }

  /// Tries to create and initialize a [HealthSensorAdapter].
  /// Returns `true` when the health store is reachable and permissions are
  /// granted.
  Future<bool> _probeHealthAdapter() async {
    try {
      final adapter = HealthSensorAdapter();
      final ok = await adapter.initialize();
      if (ok) {
        await adapter.dispose();
        return true;
      }
      await adapter.dispose();
    } catch (_) {
      // Platform may not support health at all (desktop, web, or missing
      // Google Play Services on Android).
    }
    return false;
  }

  Future<void> calibrate(List<BiometricSnapshot> readings) async {
    if (readings.isEmpty) return;

    final hrValues = readings.map((r) => r.hr).toList();
    final rmssdValues = readings.map((r) => r.hrvRmssd).toList();
    final sdnnValues = readings.map((r) => r.hrvSdnn).toList();

    final meanHr = hrValues.reduce((a, b) => a + b) / hrValues.length;
    final meanRmssd =
        rmssdValues.reduce((a, b) => a + b) / rmssdValues.length;
    final meanSdnn =
        sdnnValues.reduce((a, b) => a + b) / sdnnValues.length;

    double rmssdStd;
    if (rmssdValues.length < 2) {
      rmssdStd = meanRmssd * 0.2;
    } else {
      final meanRmssdLocal = meanRmssd;
      final sumSq = rmssdValues
          .map((v) => (v - meanRmssdLocal) * (v - meanRmssdLocal))
          .reduce((a, b) => a + b);
      rmssdStd = sumSq / (rmssdValues.length - 1);
      rmssdStd = sqrtApprox(rmssdStd);
    }

    final baseline = BiometricBaseline(
      restingHr: double.parse(meanHr.toStringAsFixed(1)),
      restingHrvRmssd: double.parse(meanRmssd.toStringAsFixed(1)),
      restingHrvSdnn: double.parse(meanSdnn.toStringAsFixed(1)),
      hrvRmssdStd: double.parse(rmssdStd.toStringAsFixed(1)),
      calibratedAt: DateTime.now(),
    );

    await _repository.saveBaseline(baseline);
    await _repository.setCalibrated(true);

    if (!_disposed) {
      state = state.copyWith(
        baseline: baseline,
        isCalibrated: true,
      );
    }
  }

  static double sqrtApprox(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Creates the best available [SensorAdapter].
  /// Prefers [HealthSensorAdapter] when health data is available; falls back
  /// to [MockSensorAdapter] otherwise.  Returns `null` when no adapter can be
  /// created (e.g. permissions permanently denied and no baseline exists).
  Future<SensorAdapter?> _createAdapter() async {
    if (state.healthAvailable) {
      final healthAdapter = HealthSensorAdapter();
      final ok = await healthAdapter.initialize();
      if (ok) return healthAdapter;
      await healthAdapter.dispose();

      // Health probe failed at session time — record the error and fall back.
      if (!_disposed) {
        state = state.copyWith(
          healthAvailable: false,
          healthError: 'Health permission revoked. Using mock data.',
          sensorMode: SensorMode.mock,
        );
      }
    }

    return MockSensorAdapter(
      baseline: state.baseline ?? BiometricBaseline.defaults,
    );
  }

  Future<void> startSession(String sessionId) async {
    if (!state.biometricsEnabled) return;
    if (_sensor == null) {
      _sensor = await _createAdapter();
      if (_sensor == null) return;
      await _sensor!.initialize();
    }
    await _sensor!.startScanning();

    _subscription = _sensor!.readings.listen((reading) {
      if (_disposed) return;
      final updatedReadings = [...state.sessionReadings, reading];
      state = state.copyWith(
        sessionReadings: updatedReadings,
        latestReading: reading,
      );
      _repository.appendSessionReading(sessionId, reading);
    });

    state = state.copyWith(isScanning: true);
  }

  MentalStateResult? evaluate(String sessionId) {
    final baseline = state.baseline;
    final latest = state.latestReading;
    if (baseline == null || latest == null) return null;

    final result = detectMentalState(latest, baseline, state.sessionReadings);

    final newMentalState = result.state;
    final now = DateTime.now();

    bool shouldAlert = false;

    if (newMentalState == MentalState.flow) {
      if (state.flowAlertCount >= 2) {
        shouldAlert = false;
      } else if (state.lastAlertTime != null &&
          now.difference(state.lastAlertTime!).inMinutes < 5) {
        shouldAlert = false;
      } else {
        shouldAlert = true;
      }

      if (shouldAlert) {
        _repository.appendSessionAlert(
          sessionId,
          BiometricAlert(
            state: MentalState.flow,
            hr: latest.hr,
            hrvRmssd: latest.hrvRmssd,
            timestamp: now,
          ),
        );

        if (!_disposed) {
          state = state.copyWith(
            currentMentalState: MentalState.flow,
            hrDeviationPct: result.hrDeviationPct,
            lastAlertTime: now,
            flowAlertCount: state.flowAlertCount + 1,
          );
        }
      }
    } else if (newMentalState == MentalState.fatigue) {
      if (state.lastFatigueAlertTime != null &&
          now.difference(state.lastFatigueAlertTime!).inMinutes < 8) {
        shouldAlert = false;
      } else {
        shouldAlert = true;
      }

      if (shouldAlert) {
        _repository.appendSessionAlert(
          sessionId,
          BiometricAlert(
            state: MentalState.fatigue,
            hr: latest.hr,
            hrvRmssd: latest.hrvRmssd,
            timestamp: now,
          ),
        );

        if (!_disposed) {
          state = state.copyWith(
            currentMentalState: MentalState.fatigue,
            hrDeviationPct: result.hrDeviationPct,
            lastAlertTime: now,
            lastFatigueAlertTime: now,
          );
        }
      }
    } else {
      if (!_disposed) {
        state = state.copyWith(
          currentMentalState: MentalState.normal,
          hrDeviationPct: result.hrDeviationPct,
        );
      }
    }

    return result;
  }

  void resetAlertState() {
    state = state.copyWith(
      currentMentalState: MentalState.normal,
      hrDeviationPct: null,
    );
  }

  Future<void> stopSession() async {
    _subscription?.cancel();
    _subscription = null;
    await _sensor?.stopScanning();

    state = state.copyWith(
      isScanning: false,
      sessionReadings: [],
      currentMentalState: MentalState.normal,
      hrDeviationPct: null,
      lastAlertTime: null,
      flowAlertCount: 0,
      lastFatigueAlertTime: null,
    );
  }

  void setSimulateFlow(bool value) {
    if (_sensor is MockSensorAdapter) {
      (_sensor as MockSensorAdapter).setSimulateFlow(value);
    }
  }

  void setSimulateFatigue(bool value) {
    if (_sensor is MockSensorAdapter) {
      (_sensor as MockSensorAdapter).setSimulateFatigue(value);
    }
  }

  Future<void> setBiometricsEnabled(bool value) async {
    await _repository.setBiometricsEnabled(value);
    if (!_disposed) {
      state = state.copyWith(biometricsEnabled: value);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _sensor?.dispose();
    super.dispose();
  }
}
