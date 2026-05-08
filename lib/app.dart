import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'timer/pages/timer_page.dart';
import 'stats/pages/stats_page.dart';
import 'settings/pages/settings_page.dart';
import 'timer/models/timer_state.dart';
import 'timer/providers/timer_provider.dart';
import 'stats/providers/stats_provider.dart';
import 'biometrics/providers/biometrics_provider.dart';
import 'calibration/pages/calibration_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class PomodoroApp extends ConsumerStatefulWidget {
  const PomodoroApp({super.key});

  @override
  ConsumerState<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends ConsumerState<PomodoroApp> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCalibration();
    });
  }

  void _checkCalibration() {
    final biometrics = ref.read(biometricsProvider);
    if (!biometrics.isCalibrated) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('🧬', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Text(
                '开启自适应专注',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            '通过心率变异性（HRV）实时感知你的专注状态，\n在最佳时刻延长计时，在疲惫时提醒休息。\n\n需要先进行 2 分钟的静息基线测量。',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final biometricsNotifier = ref.read(biometricsProvider.notifier);
                biometricsNotifier.setBiometricsEnabled(false);
                Navigator.pop(navigatorKey.currentContext!);
              },
              child: const Text(
                '暂不开启',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(navigatorKey.currentContext!);
                Navigator.of(navigatorKey.currentContext!).push(
                  MaterialPageRoute(builder: (_) => const CalibrationPage()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.workColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '开始测量',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timerProvider, (previous, next) {
      if (previous != null &&
          next.sessionPomodoros > previous.sessionPomodoros &&
          previous.mode == TimerMode.work) {
        ref.read(statsProvider.notifier).incrementPomodoro();
      }
    });

    const pages = [
      TimerPage(),
      StatsPage(),
      SettingsPage(),
    ];

    return MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_rounded),
              activeIcon: Icon(Icons.timer_rounded),
              label: '计时',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: '统计',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
