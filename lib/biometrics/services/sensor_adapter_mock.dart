import 'dart:async';
import 'dart:math';
import 'sensor_adapter.dart';
import '../models/biometric_snapshot.dart';
import '../models/biometric_baseline.dart';

class MockSensorAdapter implements SensorAdapter {
  final BiometricBaseline baseline;
  final Random _random = Random();
  StreamController<BiometricSnapshot>? _controller;
  Timer? _timer;
  bool _simulateFlow = false;
  bool _simulateFatigue = false;

  MockSensorAdapter({required this.baseline});

  void setSimulateFlow(bool value) => _simulateFlow = value;
  void setSimulateFatigue(bool value) => _simulateFatigue = value;

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<void> startScanning() async {
    _controller = StreamController<BiometricSnapshot>.broadcast();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _emitReading();
    });
  }

  void _emitReading() {
    if (_controller == null || _controller!.isClosed) return;

    double hr;
    double rmssd;
    double sdnn;

    if (_simulateFatigue) {
      hr = baseline.restingHr + 22 + _random.nextDouble() * 10;
      rmssd = baseline.restingHrvRmssd * 0.55 + _random.nextDouble() * 5;
      sdnn = baseline.restingHrvSdnn * 0.6 + _random.nextDouble() * 5;
    } else if (_simulateFlow) {
      hr = baseline.restingHr + 5 + _random.nextDouble() * 10;
      rmssd = baseline.restingHrvRmssd + _random.nextDouble() * 5 - 2;
      sdnn = baseline.restingHrvSdnn + _random.nextDouble() * 5 - 2;
    } else {
      hr = baseline.restingHr + _random.nextDouble() * 6 - 3;
      rmssd = baseline.restingHrvRmssd + _random.nextDouble() * 10 - 5;
      sdnn = baseline.restingHrvSdnn + _random.nextDouble() * 10 - 5;
    }

    _controller!.add(BiometricSnapshot(
      hr: double.parse(hr.toStringAsFixed(1)),
      hrvRmssd: double.parse(rmssd.toStringAsFixed(1)),
      hrvSdnn: double.parse(sdnn.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    ));
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
    _timer?.cancel();
    _timer = null;
    await _controller?.close();
    _controller = null;
  }

  @override
  Future<void> dispose() async {
    await stopScanning();
  }
}
