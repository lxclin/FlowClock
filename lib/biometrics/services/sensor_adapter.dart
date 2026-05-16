import '../models/biometric_snapshot.dart';

abstract class SensorAdapter {
  /// Whether this adapter reads from real device sensors (as opposed to
  /// synthetic mock data).
  bool get isHardwareBacked => false;

  Future<bool> initialize();

  Future<void> startScanning();

  Future<void> stopScanning();

  Stream<BiometricSnapshot> get readings;

  Future<void> dispose();
}
