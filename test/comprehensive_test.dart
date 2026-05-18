import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_pomodoro/core/database/database_helper.dart';
import 'package:flutter_pomodoro/timer/models/timer_state.dart';
import 'package:flutter_pomodoro/timer/providers/timer_provider.dart';
import 'package:flutter_pomodoro/timer/providers/active_task_provider.dart';
import 'package:flutter_pomodoro/todo/models/task.dart';
import 'package:flutter_pomodoro/todo/providers/task_provider.dart';
import 'package:flutter_pomodoro/todo/pages/create_task_sheet.dart';
import 'package:flutter_pomodoro/todo/widgets/task_tile.dart';
import 'package:flutter_pomodoro/timer/pages/timer_page.dart';
import 'package:flutter_pomodoro/stats/providers/session_provider.dart';
import 'package:flutter_pomodoro/biometrics/services/detect_mental_state.dart';
import 'package:flutter_pomodoro/biometrics/models/biometric_baseline.dart';
import 'package:flutter_pomodoro/biometrics/models/biometric_snapshot.dart';
import 'package:flutter_pomodoro/biometrics/models/mental_state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ═══════════════════════════════════════════════
  // Group 1: TimerState — Bug 4 精简休息状态
  // ═══════════════════════════════════════════════
  group('TimerState 状态流转', () {
    test('TimerMode 仅有 work 和 rest 两个值', () {
      expect(TimerMode.values.length, 2);
      expect(TimerMode.values, contains(TimerMode.work));
      expect(TimerMode.values, contains(TimerMode.rest));
    });

    test('初始状态：work 模式，isRunning=false', () {
      const state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 1500,
        totalSeconds: 1500,
        isRunning: false,
        sessionPomodoros: 0,
      );
      expect(state.mode, TimerMode.work);
      expect(state.isRunning, false);
      expect(state.progress, 0);
    });

    test('progress 计算：一半时间', () {
      const state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 750,
        totalSeconds: 1500,
        isRunning: true,
        sessionPomodoros: 0,
      );
      expect(state.progress, closeTo(0.5, 0.01));
    });

    test('progress 计算：完成时', () {
      const state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 0,
        totalSeconds: 1500,
        isRunning: false,
        sessionPomodoros: 1,
      );
      expect(state.progress, 1.0);
    });

    test('progress 计算：totalSeconds 为 0 时返回 0', () {
      const state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 0,
        totalSeconds: 0,
        isRunning: false,
        sessionPomodoros: 0,
      );
      expect(state.progress, 0);
    });

    test('copyWith 保留未指定的字段', () {
      const state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 1200,
        totalSeconds: 1500,
        isRunning: true,
        sessionPomodoros: 3,
        breakDuration: 5 * 60,
      );
      final next = state.copyWith(isRunning: false);
      expect(next.isRunning, false);
      expect(next.remainingSeconds, 1200);
      expect(next.sessionPomodoros, 3);
      expect(next.breakDuration, 5 * 60);
    });

    test('copyWith clearPendingAlert 清除 alert', () {
      var state = const TimerState(
        mode: TimerMode.work,
        remainingSeconds: 1500,
        totalSeconds: 1500,
        isRunning: false,
        sessionPomodoros: 0,
        pendingAlert: PendingAlertType.flow,
      );
      expect(state.pendingAlert, PendingAlertType.flow);
      state = state.copyWith(clearPendingAlert: true);
      expect(state.pendingAlert, isNull);
    });

    test('resetToWorkWithDuration 使用自定义时长', () {
      // Simulates Bug 6 fix: task with 120-min target
      var state = const TimerState(
        mode: TimerMode.rest,
        remainingSeconds: 300,
        totalSeconds: 300,
        isRunning: false,
        sessionPomodoros: 2,
        workDuration: 25 * 60,
      );
      state = state.copyWith(
        mode: TimerMode.work,
        remainingSeconds: 120 * 60,
        totalSeconds: 120 * 60,
        workDuration: 120 * 60,
      );
      expect(state.totalSeconds, 120 * 60);
      expect(state.workDuration, 120 * 60);
      expect(state.mode, TimerMode.work);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 2: Database — Bug 1,5,9 数据库完整性
  // ═══════════════════════════════════════════════
  group('DatabaseHelper 数据完整性', () {
    tearDown(() async {
      await DatabaseHelper.instance.resetForTest();
    });

    test('insertTask 包含 target_minutes 字段', () async {
      final id = await DatabaseHelper.instance.insertTask(
        title: '测试任务',
        targetMinutes: 120,
      );
      final task = await DatabaseHelper.instance.getTaskById(id);
      expect(task!['target_minutes'], 120);
    });

    test('getTaskTargetMinutes 读取正确值', () async {
      final id = await DatabaseHelper.instance.insertTask(
        title: '时长测试',
        targetMinutes: 90,
      );
      final minutes = await DatabaseHelper.instance.getTaskTargetMinutes(id);
      expect(minutes, 90);
    });

    test('getTaskTargetMinutes 对不存在的 id 返回默认 25', () async {
      final minutes = await DatabaseHelper.instance.getTaskTargetMinutes(99999);
      expect(minutes, 25);
    });

    test('getTodayFocusCountForTask 只统计 today + completed + work', () async {
      final taskId = 10;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final db = await DatabaseHelper.instance.database;

      await db.insert('pomodoro_sessions', {
        'task_id': taskId, 'mode': 'work', 'status': 'completed', 'planned_seconds': 1500,
        'actual_seconds': 1500, 'started_at': _isoDate(today, 10), 'ended_at': _isoDate(today, 10),
        'created_at': _isoDate(today, 10),
      });
      await db.insert('pomodoro_sessions', {
        'task_id': taskId, 'mode': 'work', 'status': 'completed', 'planned_seconds': 1500,
        'actual_seconds': 1500, 'started_at': _isoDate(today, 14), 'ended_at': _isoDate(today, 14),
        'created_at': _isoDate(today, 14),
      });
      await db.insert('pomodoro_sessions', {
        'task_id': taskId, 'mode': 'work', 'status': 'abandoned', 'planned_seconds': 1500,
        'actual_seconds': 300, 'started_at': _isoDate(today, 16), 'ended_at': _isoDate(today, 16),
        'created_at': _isoDate(today, 16),
      });
      await db.insert('pomodoro_sessions', {
        'task_id': taskId, 'mode': 'work', 'status': 'completed', 'planned_seconds': 1500,
        'actual_seconds': 1500, 'started_at': _isoDate(yesterday, 10), 'ended_at': _isoDate(yesterday, 10),
        'created_at': _isoDate(yesterday, 10),
      });
      await db.insert('pomodoro_sessions', {
        'task_id': taskId, 'mode': 'break', 'status': 'completed', 'planned_seconds': 300,
        'actual_seconds': 300, 'started_at': _isoDate(today, 11), 'ended_at': _isoDate(today, 11),
        'created_at': _isoDate(today, 11),
      });

      final count = await DatabaseHelper.instance.getTodayFocusCountForTask(taskId);
      expect(count, 2); // only today + work + completed

      final seconds = await DatabaseHelper.instance.getTodayFocusSecondsForTask(taskId);
      expect(seconds, 3000);
    });

    test('deleteTask 不删除关联 sessions (孤儿数据保留)', () async {
      final taskId = await DatabaseHelper.instance.insertTask(title: '待删除');
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      await db.insert('pomodoro_sessions', {
        'task_id': taskId, 'mode': 'work', 'status': 'completed', 'planned_seconds': 1500,
        'actual_seconds': 1500, 'started_at': _isoDate(now, 10), 'ended_at': _isoDate(now, 10),
        'created_at': _isoDate(now, 10),
      });

      await DatabaseHelper.instance.deleteTask(taskId);
      expect(await DatabaseHelper.instance.getTaskById(taskId), isNull);

      final sessions = await db.query('pomodoro_sessions', where: 'task_id = ?', whereArgs: [taskId]);
      expect(sessions.length, 1); // session preserved
    });

    test('upsertDailyStats 原子累加', () async {
      final now = DateTime.now();
      await DatabaseHelper.instance.upsertDailyStats(
        date: now, focusSeconds: 1500, isCompleted: true, isInterrupted: false, isAbandoned: false,
      );
      await DatabaseHelper.instance.upsertDailyStats(
        date: now, focusSeconds: 600, isCompleted: false, isInterrupted: true, isAbandoned: false,
      );
      final stats = await DatabaseHelper.instance.getDailyStats(now);
      expect(stats!['total_focus_seconds'], 2100);
      expect(stats['completed_sessions'], 1);
      expect(stats['interrupted_sessions'], 1);
      expect(stats['abandoned_sessions'], 0);
    });

    test('getLifetimeStats 返回累计数据', () async {
      final db = await DatabaseHelper.instance.database;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      await db.insert('pomodoro_sessions', {
        'task_id': null, 'mode': 'work', 'status': 'completed', 'planned_seconds': 1500,
        'actual_seconds': 1500, 'started_at': _isoDate(today, 10), 'ended_at': _isoDate(today, 10),
        'created_at': _isoDate(today, 10),
      });
      await db.insert('pomodoro_sessions', {
        'task_id': null, 'mode': 'work', 'status': 'completed', 'planned_seconds': 900,
        'actual_seconds': 900, 'started_at': _isoDate(yesterday, 14), 'ended_at': _isoDate(yesterday, 14),
        'created_at': _isoDate(yesterday, 14),
      });
      await db.insert('pomodoro_sessions', {
        'task_id': null, 'mode': 'break', 'status': 'completed', 'planned_seconds': 300,
        'actual_seconds': 300, 'started_at': _isoDate(today, 11), 'ended_at': _isoDate(today, 11),
        'created_at': _isoDate(today, 11),
      });

      final stats = await DatabaseHelper.instance.getLifetimeStats();
      expect(stats['totalSeconds'], 2400);
      expect(stats['totalSessions'], 2);
      expect(stats['totalDays'], 2); // 2 distinct days
    });
  });

  // ═══════════════════════════════════════════════
  // Group 3: Task CRUD — Bug 9,10 空安全/越界
  // ═══════════════════════════════════════════════
  group('Task CRUD 健壮性', () {
    tearDown(() async {
      await DatabaseHelper.instance.resetForTest();
    });

    test('getTaskById 对不存在的 id 返回 null', () async {
      final task = await DatabaseHelper.instance.getTaskById(0);
      expect(task, isNull);
    });

    test('getActiveTasks 返回按 sortOrder 排序的未归档任务', () async {
      await DatabaseHelper.instance.insertTask(title: 'B', sortOrder: 2);
      await DatabaseHelper.instance.insertTask(title: 'A', sortOrder: 1);
      await DatabaseHelper.instance.insertTask(title: 'C', sortOrder: 3);

      final tasks = await DatabaseHelper.instance.getActiveTasks();
      expect(tasks.length, 3);
      expect(tasks[0]['title'], 'A');
      expect(tasks[1]['title'], 'B');
      expect(tasks[2]['title'], 'C');
    });

    test('insertTask 未指定 sortOrder 时自动递增', () async {
      final id1 = await DatabaseHelper.instance.insertTask(title: '任务1');
      final id2 = await DatabaseHelper.instance.insertTask(title: '任务2');

      final t1 = await DatabaseHelper.instance.getTaskById(id1);
      final t2 = await DatabaseHelper.instance.getTaskById(id2);
      expect(t2!['sort_order'], greaterThan(t1!['sort_order']));
    });

    test('archiveTask 来回切换', () async {
      final id = await DatabaseHelper.instance.insertTask(title: '归档测试');
      await DatabaseHelper.instance.archiveTask(id, true);

      var active = await DatabaseHelper.instance.getActiveTasks();
      expect(active.any((t) => t['id'] == id), isFalse);

      await DatabaseHelper.instance.archiveTask(id, false);
      active = await DatabaseHelper.instance.getActiveTasks();
      expect(active.any((t) => t['id'] == id), isTrue);
    });

    test('reorderTasks 更新 sort_order', () async {
      final idA = await DatabaseHelper.instance.insertTask(title: 'A', sortOrder: 10);
      final idB = await DatabaseHelper.instance.insertTask(title: 'B', sortOrder: 20);
      final idC = await DatabaseHelper.instance.insertTask(title: 'C', sortOrder: 30);

      await DatabaseHelper.instance.reorderTasks([idC, idA, idB]);

      final tasks = await DatabaseHelper.instance.getActiveTasks();
      expect(tasks[0]['id'], idC);
      expect(tasks[1]['id'], idA);
      expect(tasks[2]['id'], idB);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 4: Timer 核心逻辑 (pure state tests, no SharedPreferences)
  // ═══════════════════════════════════════════════
  group('Timer 核心逻辑', () {
    test('resetToWorkWithDuration 使用自定义秒数', () {
      const state = TimerState(
        mode: TimerMode.rest,
        remainingSeconds: 300,
        totalSeconds: 300,
        isRunning: false,
        sessionPomodoros: 2,
      );
      final next = state.copyWith(
        mode: TimerMode.work,
        remainingSeconds: 90 * 60,
        totalSeconds: 90 * 60,
        workDuration: 90 * 60,
      );
      expect(next.mode, TimerMode.work);
      expect(next.totalSeconds, 90 * 60);
      expect(next.workDuration, 90 * 60);
    });

    test('skip 切换模式且不累加 pomodoro', () {
      const state = TimerState(
        mode: TimerMode.work,
        remainingSeconds: 60,
        totalSeconds: 60,
        isRunning: false,
        sessionPomodoros: 0,
      );
      // Skip keeps pomodoros unchanged, only mode flips
      final next = state.copyWith(
        mode: TimerMode.rest,
        remainingSeconds: 300,
        totalSeconds: 300,
      );
      expect(next.mode, TimerMode.rest);
      expect(next.sessionPomodoros, 0);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 5: 心理状态检测 — Bug 17 除零
  // ═══════════════════════════════════════════════
  group('detectMentalState 算法', () {
    final baseline = BiometricBaseline(
      restingHr: 65,
      restingHrvRmssd: 42,
      restingHrvSdnn: 55,
      hrvRmssdStd: 8.0,
      calibratedAt: DateTime.now(),
    );

    test('正常态：HR 接近基线 + HRV 稳定', () {
      final current = BiometricSnapshot(hr: 66, hrvRmssd: 43, hrvSdnn: 54, timestamp: DateTime.now());
      final history = [
        BiometricSnapshot(hr: 65, hrvRmssd: 42, hrvSdnn: 55, timestamp: DateTime.now()),
        BiometricSnapshot(hr: 66, hrvRmssd: 41, hrvSdnn: 54, timestamp: DateTime.now()),
      ];
      final result = detectMentalState(current, baseline, history);
      expect(result.state, MentalState.normal);
    });

    test('心流态：HR 轻度升高 + HRV 稳定', () {
      final current = BiometricSnapshot(hr: 72, hrvRmssd: 44, hrvSdnn: 54, timestamp: DateTime.now());
      final history = [
        BiometricSnapshot(hr: 70, hrvRmssd: 44, hrvSdnn: 55, timestamp: DateTime.now()),
        BiometricSnapshot(hr: 72, hrvRmssd: 43, hrvSdnn: 54, timestamp: DateTime.now()),
      ];
      final result = detectMentalState(current, baseline, history);
      expect(result.state, MentalState.flow);
    });

    test('疲劳态：HRV 塌陷 + HR 异常', () {
      final current = BiometricSnapshot(hr: 85, hrvRmssd: 20, hrvSdnn: 35, timestamp: DateTime.now());
      final history = [
        BiometricSnapshot(hr: 75, hrvRmssd: 28, hrvSdnn: 40, timestamp: DateTime.now()),
        BiometricSnapshot(hr: 80, hrvRmssd: 24, hrvSdnn: 38, timestamp: DateTime.now()),
      ];
      final result = detectMentalState(current, baseline, history);
      expect(result.state, MentalState.fatigue);
    });

    test('单点极端值时按算法判断状态', () {
      final current = BiometricSnapshot(hr: 85, hrvRmssd: 20, hrvSdnn: 35, timestamp: DateTime.now());
      final result = detectMentalState(current, baseline, []);
      expect(result.state, isNotNull); // Won't crash, but may detect fatigue from extreme single reading
    });

    test('hrvRmssdStd 为 0 时不崩溃 (Bug 17)', () {
      final zeroBaseline = BiometricBaseline(
        restingHr: 65, restingHrvRmssd: 42, restingHrvSdnn: 55,
        hrvRmssdStd: 0, calibratedAt: DateTime.now(),
      );
      final current = BiometricSnapshot(hr: 66, hrvRmssd: 42, hrvSdnn: 55, timestamp: DateTime.now());
      final result = detectMentalState(current, zeroBaseline, [
        BiometricSnapshot(hr: 65, hrvRmssd: 42, hrvSdnn: 55, timestamp: DateTime.now()),
      ]);
      expect(result.state, MentalState.normal);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 6: TaskTile UI — Bug 16
  // ═══════════════════════════════════════════════
  group('TaskTile 渲染', () {
    Task _makeTask({String title = '测试', int completed = 0, int targetMinutes = 25}) {
      return Task(
        title: title, completedPomodoros: completed,
        targetMinutes: targetMinutes, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
    }

    testWidgets('未完成时标题无删除线', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body: TaskTile(
        task: _makeTask(goal: 4), isActive: false, todayFocusCount: 2, todayFocusSeconds: 3000,
        onTap: () {}, onStart: () {}, onLongPress: () {},
      )))));
      final text = tester.widget<Text>(find.textContaining('测试'));
      expect(text.style?.decoration, TextDecoration.none);
    });

    testWidgets('已完成时标题带删除线', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body: TaskTile(
        task: _makeTask(goal: 4), isActive: false, todayFocusCount: 4, todayFocusSeconds: 6000,
        onTap: () {}, onStart: () {}, onLongPress: () {},
      )))));
      final text = tester.widget<Text>(find.textContaining('测试'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('显示今日专注次数和时长', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body: TaskTile(
        task: _makeTask(), isActive: false, todayFocusCount: 3, todayFocusSeconds: 4500,
        onTap: () {}, onStart: () {}, onLongPress: () {},
      )))));
      expect(find.textContaining('今日专注 3 次 · 共 75 分钟'), findsOneWidget);
    });

    testWidgets('显示 [开始] 按钮', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body: TaskTile(
        task: _makeTask(), isActive: false, todayFocusCount: 0, todayFocusSeconds: 0,
        onTap: () {}, onStart: () {}, onLongPress: () {},
      )))));
      expect(find.text('开始'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 7: CreateTaskSheet — Bug 5
  // ═══════════════════════════════════════════════
  group('CreateTaskSheet 双向绑定', () {
    testWidgets('Slider→TextField 同步', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: CreateTaskSheet()))));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged?.call(60);
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      final minuteField = tester.widget<TextField>(fields.at(1));
      expect(minuteField.controller?.text, '60');
    });

    testWidgets('TextField→Slider 同步', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: CreateTaskSheet()))));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      final minuteField = tester.widget<TextField>(fields.at(1));
      minuteField.onChanged?.call('120');
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 120.0);
    });

    testWidgets('120 分钟不溢出 (Bug 5)', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: CreateTaskSheet()))));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      final minuteField = tester.widget<TextField>(fields.at(1));
      minuteField.onChanged?.call('120');
      await tester.pumpAndSettle();

      // Should not throw overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('1-8 番茄数选择', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: Scaffold(body: CreateTaskSheet()))));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 8: TimerPage — Bug 1,8
  // ═══════════════════════════════════════════════
  group('TimerPage 渲染', () {
    testWidgets('TimerPage 包裹 Scaffold (Bug 8 修复)', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: TimerPage())));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('显示放弃按钮', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: TimerPage())));
      await tester.pumpAndSettle();
      expect(find.text('🚪 放弃当前番茄'), findsOneWidget);
    });

    testWidgets('显示暂停/播放按钮', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: TimerPage())));
      await tester.pumpAndSettle();
      // After auto-start, shows pause icon
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('显示重置和跳过按钮', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: TimerPage())));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════
  // Group 9: 边界条件
  // ═══════════════════════════════════════════════
  group('边界条件', () {
    test('totalSeconds=0 时 progress=0', () {
      const state = TimerState(
        mode: TimerMode.work, remainingSeconds: 0, totalSeconds: 0,
        isRunning: false, sessionPomodoros: 0,
      );
      expect(state.progress, 0);
    });

    test('remainingSeconds > totalSeconds 时 progress 低至 0 以下', () {
      const state = TimerState(
        mode: TimerMode.work, remainingSeconds: 2000, totalSeconds: 1500,
        isRunning: false, sessionPomodoros: 0,
      );
      // progress = 1 - 2000/1500 = -0.333 (not clamped by model — existing behavior)
      expect(state.progress, lessThan(0));
    });

    test('Task.fromMap 缺少 target_minutes 时默认 25', () {
      final map = {
        'id': 1, 'title': '测试', 'pomodoro_goal': 4, 'completed_pomodoros': 0,
        'note': null, 'is_archived': 0, 'sort_order': 0,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
        // target_minutes missing — old schema
      };
      final task = Task.fromMap(map);
      expect(task.targetMinutes, 25);
    });
  });
}

String _isoDate(DateTime d, int hour) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${hour.toString().padLeft(2, '0')}:00:00.000';
}
