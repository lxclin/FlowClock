import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/biometric_baseline.dart';
import '../models/biometric_snapshot.dart';
import '../models/biometric_alert.dart';

class BiometricsRepository {
  static const _keyBaseline = 'bio_baseline';
  static const _keyCalibrated = 'bio_calibrated';
  static const _keySessionReadings = 'bio_session_readings';
  static const _keySessionAlerts = 'bio_session_alerts';
  static const _keyBiometricsEnabled = 'bio_enabled';

  final SharedPreferences _prefs;

  BiometricsRepository(this._prefs);

  Future<BiometricBaseline?> getBaseline() async {
    final json = _prefs.getString(_keyBaseline);
    if (json == null) return null;
    return BiometricBaseline.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveBaseline(BiometricBaseline baseline) async {
    await _prefs.setString(_keyBaseline, jsonEncode(baseline.toJson()));
  }

  bool get isCalibrated => _prefs.getBool(_keyCalibrated) ?? false;

  Future<void> setCalibrated(bool value) async {
    await _prefs.setBool(_keyCalibrated, value);
  }

  bool get biometricsEnabled => _prefs.getBool(_keyBiometricsEnabled) ?? false;

  Future<void> setBiometricsEnabled(bool value) async {
    await _prefs.setBool(_keyBiometricsEnabled, value);
  }

  Future<List<BiometricSnapshot>> getSessionReadings(
      String sessionId) async {
    final json = _prefs.getString('$_keySessionReadings:$sessionId');
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => BiometricSnapshot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSessionReadings(
      String sessionId, List<BiometricSnapshot> readings) async {
    final json = jsonEncode(readings.map((r) => r.toJson()).toList());
    await _prefs.setString('$_keySessionReadings:$sessionId', json);
  }

  Future<void> appendSessionReading(
      String sessionId, BiometricSnapshot reading) async {
    final readings = await getSessionReadings(sessionId);
    readings.add(reading);
    await saveSessionReadings(sessionId, readings);
  }

  Future<List<BiometricAlert>> getSessionAlerts(String sessionId) async {
    final json = _prefs.getString('$_keySessionAlerts:$sessionId');
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => BiometricAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> appendSessionAlert(
      String sessionId, BiometricAlert alert) async {
    final alerts = await getSessionAlerts(sessionId);
    alerts.add(alert);
    final json = jsonEncode(alerts.map((a) => a.toJson()).toList());
    await _prefs.setString('$_keySessionAlerts:$sessionId', json);
  }

  Future<void> clearSessionData(String sessionId) async {
    await _prefs.remove('$_keySessionReadings:$sessionId');
    await _prefs.remove('$_keySessionAlerts:$sessionId');
  }
}
