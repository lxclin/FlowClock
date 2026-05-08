import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../biometrics/providers/biometrics_provider.dart';
import '../../biometrics/models/biometric_snapshot.dart';

class CalibrationPage extends ConsumerStatefulWidget {
  const CalibrationPage({super.key});

  @override
  ConsumerState<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends ConsumerState<CalibrationPage> {
  int _elapsed = 0;
  final int _totalSeconds = 120;
  final List<BiometricSnapshot> _readings = [];
  Timer? _timer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _elapsed++;
        _readings.add(BiometricSnapshot(
          hr: 65.0 + (_elapsed % 7 - 3),
          hrvRmssd: 42.0 + (_elapsed % 10 - 5),
          hrvSdnn: 53.0 + (_elapsed % 8 - 4),
          timestamp: DateTime.now(),
        ));
        if (_elapsed >= _totalSeconds) {
          _isComplete = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _elapsed / _totalSeconds;
    final remaining = _totalSeconds - _elapsed;
    final rm = remaining ~/ 60;
    final rs = remaining % 60;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.workBackground, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  '🧬 建立你的生理基线',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '请安静坐下，自然呼吸\n我们会测量你的静息心率和HRV',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const Spacer(flex: 1),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: AppTheme.trackColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.workColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isComplete)
                            const Icon(
                              Icons.check_circle,
                              size: 48,
                              color: AppTheme.workColor,
                            )
                          else ...[
                            Text(
                              '${rm.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _readings.isNotEmpty
                                  ? '❤️ ${_readings.last.hr.toStringAsFixed(0)} bpm'
                                  : '测量中…',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                if (_isComplete)
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(biometricsProvider.notifier)
                          .calibrate(_readings);
                      ref
                          .read(biometricsProvider.notifier)
                          .setBiometricsEnabled(true);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.workColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '开始使用',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Text(
                    '保持自然呼吸，不要刻意深呼吸',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                const SizedBox(height: 20),
                if (!_isComplete)
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      ref
                          .read(biometricsProvider.notifier)
                          .calibrate(_readings);
                      ref
                          .read(biometricsProvider.notifier)
                          .setBiometricsEnabled(true);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '跳过校准',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
