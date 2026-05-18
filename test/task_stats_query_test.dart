import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_pomodoro/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _insertSession({
    required int taskId,
    required String date,
    required String status,
    required String mode,
    int actualSeconds = 1500,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('pomodoro_sessions', {
      'task_id': taskId,
      'mode': mode,
      'status': status,
      'planned_seconds': 1500,
      'actual_seconds': actualSeconds,
      'started_at': '$date 10:00:00.000',
      'ended_at': '$date 10:25:00.000',
      'created_at': '$date 10:25:00.000',
    });
  }

  group('DatabaseHelper — Task 当日查询', () {
    test('getTodayFocusCountForTask 返回今日完成次数', () async {
      final taskId = 1;
      final today = _todayKey();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      await _insertSession(taskId: taskId, date: today, status: 'completed', mode: 'work');
      await _insertSession(taskId: taskId, date: today, status: 'completed', mode: 'work');
      await _insertSession(taskId: taskId, date: today, status: 'completed', mode: 'work');
      await _insertSession(taskId: taskId, date: yKey, status: 'completed', mode: 'work');
      await _insertSession(taskId: taskId, date: today, status: 'abandoned', mode: 'work');

      final count = await DatabaseHelper.instance.getTodayFocusCountForTask(taskId);
      expect(count, 3);
    });

    test('getTodayFocusSecondsForTask 返回今日总秒数', () async {
      final taskId = 2;
      final today = _todayKey();

      await _insertSession(taskId: taskId, date: today, status: 'completed', mode: 'work',
          actualSeconds: 1500);
      await _insertSession(taskId: taskId, date: today, status: 'completed', mode: 'work',
          actualSeconds: 1200);

      final seconds = await DatabaseHelper.instance.getTodayFocusSecondsForTask(taskId);
      expect(seconds, 2700);
    });

    test('getTodayFocusCountForTask 无数据返回 0', () async {
      final count = await DatabaseHelper.instance.getTodayFocusCountForTask(999);
      expect(count, 0);
    });
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTest();
  });
}
