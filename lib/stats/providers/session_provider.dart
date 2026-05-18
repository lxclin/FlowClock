import '../../core/database/database_helper.dart';

class SessionRecorder {
  static Future<void> recordCompleted({
    int? taskId,
    required String mode,
    required int plannedSeconds,
    required int actualSeconds,
    required DateTime startedAt,
  }) async {
    final now = DateTime.now();
    await DatabaseHelper.instance.insertSession(
      taskId: taskId,
      mode: mode,
      status: 'completed',
      plannedSeconds: plannedSeconds,
      actualSeconds: actualSeconds,
      startedAt: startedAt,
    );

    await DatabaseHelper.instance.upsertDailyStats(
      date: now,
      focusSeconds: mode == 'work' ? actualSeconds : 0,
      isCompleted: true,
      isInterrupted: false,
      isAbandoned: false,
    );

    if (mode == 'work') {
      await DatabaseHelper.instance.upsertHourlyDistribution(
        date: now,
        hour: DateTime.now().hour,
        focusSeconds: actualSeconds,
      );
    }
  }

  static Future<void> recordInterrupted({
    int? taskId,
    required String mode,
    required int plannedSeconds,
    required int actualSeconds,
    required DateTime startedAt,
  }) async {
    final now = DateTime.now();
    await DatabaseHelper.instance.insertSession(
      taskId: taskId,
      mode: mode,
      status: 'interrupted',
      plannedSeconds: plannedSeconds,
      actualSeconds: actualSeconds,
      interruptedAtSecond: actualSeconds,
      startedAt: startedAt,
    );

    await DatabaseHelper.instance.upsertDailyStats(
      date: now,
      focusSeconds: actualSeconds,
      isCompleted: false,
      isInterrupted: true,
      isAbandoned: false,
    );
  }

  static Future<void> recordAbandoned({
    int? taskId,
    required String mode,
    required int plannedSeconds,
    required int actualSeconds,
    required DateTime startedAt,
  }) async {
    final now = DateTime.now();
    await DatabaseHelper.instance.insertSession(
      taskId: taskId,
      mode: mode,
      status: 'abandoned',
      plannedSeconds: plannedSeconds,
      actualSeconds: actualSeconds,
      interruptedAtSecond: actualSeconds,
      startedAt: startedAt,
    );

    await DatabaseHelper.instance.upsertDailyStats(
      date: now,
      focusSeconds: actualSeconds,
      isCompleted: false,
      isInterrupted: false,
      isAbandoned: true,
    );
  }
}
