import 'dart:async';

import 'package:health/health.dart';

import '../models/biometric_snapshot.dart';
import 'sensor_adapter.dart';

/// Wraps the `health` plugin to read resting heart rate and real-time HRV
/// (RMSSD + SDNN) from Apple HealthKit (iOS) or Google Health Connect
/// (Android).
///
/// Polls every [kPollInterval] for the latest HR / HRV samples within the
/// trailing [kFetchWindow].  On platforms without health hardware the
/// [initialize] call returns `false` and the caller should fall back to mock.
class HealthSensorAdapter implements SensorAdapter {
  static const kPollInterval = Duration(seconds: 10);
  static const kFetchWindow = Duration(minutes: 2);

  final Health _health;
  final List<HealthDataType> _types = const [
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.RESTING_HEART_RATE,
  ];

  StreamController<BiometricSnapshot>? _controller;
  Timer? _pollingTimer;
  bool _initialized = false;

  HealthSensorAdapter() : _health = Health();

  @override
  bool get isHardwareBacked => true;

  /// Returns `true` when the user grants read access for HR + HRV.
  /// Returns `false` when the platform does not support health data,
  /// the user denies permission, or any other error occurs.
  @override
  Future<bool> initialize() async {
    try {
      await _health.configure();
      final authorized = await _health.requestAuthorization(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.READ),
      );
      if (!authorized) return false;
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startScanning() async {
    if (!_initialized) return;
    _controller = StreamController<BiometricSnapshot>.broadcast(
      onCancel: () {},
    );

    await _fetchAndEmit();
    _pollingTimer = Timer.periodic(kPollInterval, (_) => _fetchAndEmit());
  }

  /// Fetches the most-recent HR and HRV samples from the health store and
  /// emits a unified [BiometricSnapshot].  If HRV is unavailable (common on
  /// some wearables) a placeholder is used so the detection pipeline can
  /// still operate on HR data alone.
  Future<void> _fetchAndEmit() async {
    if (_controller == null || _controller!.isClosed) return;

    try {
      final now = DateTime.now();
      final start = now.subtract(kFetchWindow);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _types,
      );
      if (data.isEmpty) return;

      final hrPoints = data
          .where((d) =>
              d.type == HealthDataType.HEART_RATE ||
              d.type == HealthDataType.RESTING_HEART_RATE)
          .toList();
      final rmssdPoints = data
          .where((d) => d.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD)
          .toList();
      final sdnnPoints = data
          .where((d) => d.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN)
          .toList();

      if (hrPoints.isEmpty) return;

      final hr = (hrPoints.last.value as NumericHealthValue)
          .numericValue
          .toDouble();

      // Prefer native RMSSD when available; otherwise derive from SDNN.
      double rmssd;
      if (rmssdPoints.isNotEmpty) {
        rmssd = (rmssdPoints.last.value as NumericHealthValue)
            .numericValue
            .toDouble();
      } else if (sdnnPoints.isNotEmpty) {
        final sdnn = (sdnnPoints.last.value as NumericHealthValue)
            .numericValue
            .toDouble();
        rmssd = sdnn * 0.85; // empirical approximation
      } else {
        rmssd = 42.0;
      }

      double sdnn;
      if (sdnnPoints.isNotEmpty) {
        sdnn = (sdnnPoints.last.value as NumericHealthValue)
            .numericValue
            .toDouble();
      } else {
        sdnn = rmssd / 0.85;
      }

      _controller!.add(BiometricSnapshot(
        hr: double.parse(hr.toStringAsFixed(1)),
        hrvRmssd: double.parse(rmssd.toStringAsFixed(1)),
        hrvSdnn: double.parse(sdnn.toStringAsFixed(1)),
        timestamp: now,
      ));
    } catch (_) {
      // Polling errors are swallowed — intermittent connectivity or sensor
      // dropout should not tear down the stream.
    }
  }

  @override
  Stream<BiometricSnapshot> get readings {
    if (_controller == null) {
      throw StateError('Call startScanning() before accessing readings');
    }
    return _controller!.stream;
  }

  @override
  Future<void> stopScanning() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _controller?.close();
    _controller = null;
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
  }
}
