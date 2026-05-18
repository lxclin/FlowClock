import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'todo/pages/todo_page.dart';
import 'stats/pages/stats_page.dart';
import 'settings/pages/settings_page.dart';
import 'timer/models/timer_state.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRecovery());
  }

  void _checkRecovery() {
    // TODO: read recovery snapshot from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      TodoPage(),
      StatsPage(),
      SettingsPage(),
    ];

    final labels = const ['任务', '统计', '设置'];
    final icons = const [Icons.checklist_rounded, Icons.bar_chart_rounded, Icons.settings_rounded];

    return MaterialApp(
      title: 'FlowClock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: List.generate(3, (i) => BottomNavigationBarItem(
                icon: Icon(icons[i]),
                activeIcon: Icon(icons[i]),
                label: labels[i],
              )),
        ),
      ),
    );
  }
}
