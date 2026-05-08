import '../models/biometric_snapshot.dart';

abstract class SensorAdapter {
  Future<bool> initialize();

  Future<void> startScanning();

  Future<void> stopScanning();

  Stream<BiometricSnapshot> get readings;

  Future<void> dispose();
}
