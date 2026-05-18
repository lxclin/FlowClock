import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_pomodoro/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper — 建表', () {
    test('should create all 4 tables', () async {
      final db = await DatabaseHelper.instance.database;

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name'] as String).toList();

      expect(names, contains('tasks'));
      expect(names, contains('pomodoro_sessions'));
      expect(names, contains('daily_stats'));
      expect(names, contains('hourly_distribution'));
    });

    test('tasks table should have correct columns', () async {
      final db = await DatabaseHelper.instance.database;
      final cols = await db.rawQuery('PRAGMA table_info(tasks)');
      final colNames = cols.map((c) => c['name'] as String).toList();

      expect(colNames, containsAll([
            'id', 'title', 'pomodoro_goal', 'completed_pomodoros',
            'note', 'is_archived', 'sort_order', 'created_at', 'updated_at',
          ]));
    });

    test('pomodoro_sessions table should have correct columns', () async {
      final db = await DatabaseHelper.instance.database;
      final cols = await db.rawQuery('PRAGMA table_info(pomodoro_sessions)');
      final colNames = cols.map((c) => c['name'] as String).toList();

      expect(colNames, containsAll([
            'id', 'task_id', 'mode', 'status', 'planned_seconds',
            'actual_seconds', 'interrupted_at_second', 'started_at',
            'ended_at', 'created_at',
          ]));
    });
  });

  group('DatabaseHelper — Task CRUD', () {
    test('should insert and read a task', () async {
      final id = await DatabaseHelper.instance.insertTask(
        title: '完成项目报告',
        note: '需要深度专注',
      );

      expect(id, greaterThan(0));

      final tasks = await DatabaseHelper.instance.getActiveTasks();
      expect(tasks.length, greaterThanOrEqualTo(1));
      expect(tasks.any((t) => t['title'] == '完成项目报告'), isTrue);
    });

    test('should update task fields', () async {
      final id = await DatabaseHelper.instance.insertTask(
        title: '旧标题',
        );

      await DatabaseHelper.instance.updateTask(
        id: id,
        title: '新标题',
        note: '已更新备注',
      );

      final task = await DatabaseHelper.instance.getTaskById(id);
      expect(task!['title'], '新标题');
      expect(task['pomodoro_goal'], 5);
      expect(task['note'], '已更新备注');
    });

    test('should archive and unarchive a task', () async {
      final id = await DatabaseHelper.instance.insertTask(
        title: '待归档任务',
        );

      await DatabaseHelper.instance.archiveTask(id, true);
      var active = await DatabaseHelper.instance.getActiveTasks();
      expect(active.any((t) => t['id'] == id), isFalse);

      await DatabaseHelper.instance.archiveTask(id, false);
      active = await DatabaseHelper.instance.getActiveTasks();
      expect(active.any((t) => t['id'] == id), isTrue);
    });

    test('should delete a task', () async {
      final id = await DatabaseHelper.instance.insertTask(
        title: '待删除任务',
        );

      await DatabaseHelper.instance.deleteTask(id);

      final task = await DatabaseHelper.instance.getTaskById(id);
      expect(task, isNull);
    });

    test('should reorder tasks', () async {
      final id1 = await DatabaseHelper.instance.insertTask(
        title: '任务A',
        sortOrder: 0,
      );
      final id2 = await DatabaseHelper.instance.insertTask(
        title: '任务B',
        sortOrder: 1,
      );

      await DatabaseHelper.instance.reorderTasks([id2, id1]);

      final tasks = await DatabaseHelper.instance.getActiveTasks();
      expect(tasks[0]['id'], id2);
      expect(tasks[1]['id'], id1);
    });
  });

  group('DatabaseHelper — Session Recording', () {
    test('should insert a completed work session', () async {
      final sessionId = await DatabaseHelper.instance.insertSession(
        taskId: null,
        mode: 'work',
        status: 'completed',
        plannedSeconds: 1500,
        actualSeconds: 1500,
        startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      );

      expect(sessionId, greaterThan(0));

      final sessions = await DatabaseHelper.instance.getSessionsForDate(
        DateTime.now(),
      );
      expect(sessions.isNotEmpty, isTrue);
    });

    test('should insert an interrupted session with interrupted seconds', () async {
      final sessionId = await DatabaseHelper.instance.insertSession(
        taskId: 1,
        mode: 'work',
        status: 'interrupted',
        plannedSeconds: 1500,
        actualSeconds: 480,
        interruptedAtSecond: 480,
        startedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      );

      expect(sessionId, greaterThan(0));

      final sessions = await DatabaseHelper.instance.getInterruptedCount(
        DateTime.now(),
      );
      expect(sessions, greaterThanOrEqualTo(1));
    });

    test('should insert an abandoned session', () async {
      await DatabaseHelper.instance.insertSession(
        mode: 'work',
        status: 'abandoned',
        plannedSeconds: 1500,
        actualSeconds: 90,
        interruptedAtSecond: 90,
        startedAt: DateTime.now(),
      );

      final abandoned = await DatabaseHelper.instance.getAbandonedCount(
        DateTime.now(),
      );
      expect(abandoned, greaterThanOrEqualTo(1));
    });

    test('should link sessions to a task', () async {
      final taskId = await DatabaseHelper.instance.insertTask(
        title: '关联任务',
        );

      await DatabaseHelper.instance.insertSession(
        taskId: taskId,
        mode: 'work',
        status: 'completed',
        plannedSeconds: 1500,
        actualSeconds: 1500,
        startedAt: DateTime.now(),
      );

      final sessions = await DatabaseHelper.instance.getSessionsByTask(taskId);
      expect(sessions.length, 1);
      expect(sessions.first['task_id'], taskId);
    });
  });

  group('DatabaseHelper — Daily Stats', () {
    test('should upsert daily stats correctly', () async {
      final today = DateTime.now();

      await DatabaseHelper.instance.upsertDailyStats(
        date: today,
        focusSeconds: 1500,
        isCompleted: true,
        isInterrupted: false,
        isAbandoned: false,
      );

      await DatabaseHelper.instance.upsertDailyStats(
        date: today,
        focusSeconds: 1500,
        isCompleted: true,
        isInterrupted: false,
        isAbandoned: false,
      );

      final stats = await DatabaseHelper.instance.getDailyStats(today);
      expect(stats!['total_focus_seconds'], 3000);
      expect(stats['completed_sessions'], 2);
    });

    test('should record interrupted/abandoned in daily stats', () async {
      final today = DateTime.now();

      await DatabaseHelper.instance.upsertDailyStats(
        date: today,
        focusSeconds: 400,
        isCompleted: false,
        isInterrupted: true,
        isAbandoned: false,
      );

      final stats = await DatabaseHelper.instance.getDailyStats(today);
      expect(stats!['total_focus_seconds'], greaterThanOrEqualTo(400));
    });

    test('should return null for date with no data', () async {
      final d = DateTime(2020, 1, 1);
      final stats = await DatabaseHelper.instance.getDailyStats(d);
      expect(stats, isNull);
    });
  });

  group('DatabaseHelper — Hourly Distribution', () {
    test('should upsert hourly distribution', () async {
      final now = DateTime.now();

      await DatabaseHelper.instance.upsertHourlyDistribution(
        date: now,
        hour: 9,
        focusSeconds: 1500,
      );

      await DatabaseHelper.instance.upsertHourlyDistribution(
        date: now,
        hour: 9,
        focusSeconds: 1500,
      );

      final hours = await DatabaseHelper.instance.getHourlyDistribution(now);
      final hour9 = hours.firstWhere((h) => h['hour'] == 9);
      expect(hour9['focus_seconds'], 3000);
      expect(hour9['sessions_count'], 2);
    });
  });

  group('DatabaseHelper — Multi-dimensional query', () {
    test('should get focus time by task', () async {
      final taskId = await DatabaseHelper.instance.insertTask(
        title: '统计来源任务',
        );

      await DatabaseHelper.instance.insertSession(
        taskId: taskId,
        mode: 'work',
        status: 'completed',
        plannedSeconds: 1500,
        actualSeconds: 1500,
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await DatabaseHelper.instance.insertSession(
        taskId: taskId,
        mode: 'work',
        status: 'completed',
        plannedSeconds: 1500,
        actualSeconds: 1200,
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final result = await DatabaseHelper.instance.getFocusTimeByTask(taskId);
      expect(result['total_seconds'], 2700);
      expect(result['session_count'], 2);
    });

    test('should get weekly stats summary', () async {
      final result = await DatabaseHelper.instance.getWeeklyStats();
      expect(result, isA<List<Map<String, dynamic>>>());
    });
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTest();
  });
}
