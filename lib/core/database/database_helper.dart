import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'flowclock.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS hourly_distribution');
      await db.execute('''
        CREATE TABLE hourly_distribution (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          hour INTEGER NOT NULL,
          focus_seconds INTEGER NOT NULL DEFAULT 0,
          sessions_count INTEGER NOT NULL DEFAULT 0,
          UNIQUE(date, hour)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN target_minutes INTEGER NOT NULL DEFAULT 25');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        pomodoro_goal INTEGER NOT NULL DEFAULT 1,
        completed_pomodoros INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        target_minutes INTEGER NOT NULL DEFAULT 25,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        mode TEXT NOT NULL,
        status TEXT NOT NULL,
        planned_seconds INTEGER NOT NULL,
        actual_seconds INTEGER NOT NULL DEFAULT 0,
        interrupted_at_second INTEGER,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        date TEXT PRIMARY KEY,
        total_focus_seconds INTEGER NOT NULL DEFAULT 0,
        completed_sessions INTEGER NOT NULL DEFAULT 0,
        interrupted_sessions INTEGER NOT NULL DEFAULT 0,
        abandoned_sessions INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE hourly_distribution (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        hour INTEGER NOT NULL,
        focus_seconds INTEGER NOT NULL DEFAULT 0,
        sessions_count INTEGER NOT NULL DEFAULT 0,
        UNIQUE(date, hour)
      )
    ''');
  }

  // ── Task CRUD ──

  Future<int> insertTask({
    required String title,
    String? note,
    int sortOrder = 0,
    int targetMinutes = 25,
  }) async {
    final db = await database;
    final now = _nowIso();
    final maxOrder = (await db.rawQuery('SELECT MAX(sort_order) AS m FROM tasks WHERE is_archived=0'))
        .first['m'] as int?;
    final order = sortOrder > 0 ? sortOrder : (maxOrder ?? 0) + 1;

    return await db.insert('tasks', {
      'title': title,
      'note': note,
      'sort_order': order,
      'target_minutes': targetMinutes,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateTask({
    required int id,
    String? title,
    int? targetMinutes,
    String? note,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'updated_at': _nowIso()};
    if (title != null) values['title'] = title;
    if (targetMinutes != null) values['target_minutes'] = targetMinutes;
    if (note != null) values['note'] = note;

    await db.update('tasks', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementTaskPomodoro(int taskId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE tasks SET completed_pomodoros = completed_pomodoros + 1, updated_at = ? WHERE id = ?',
      [_nowIso(), taskId],
    );
  }

  Future<void> archiveTask(int id, bool archive) async {
    final db = await database;
    await db.update(
      'tasks',
      {'is_archived': archive ? 1 : 0, 'updated_at': _nowIso()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderTasks(List<int> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update('tasks', {'sort_order': i}, where: 'id = ?', whereArgs: [orderedIds[i]]);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getTaskById(int id) async {
    final db = await database;
    final results = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getActiveTasks() async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'is_archived = 0',
      orderBy: 'sort_order ASC',
    );
  }

  // ── Session Recording ──

  Future<int> insertSession({
    int? taskId,
    required String mode,
    required String status,
    required int plannedSeconds,
    int actualSeconds = 0,
    int? interruptedAtSecond,
    required DateTime startedAt,
  }) async {
    final db = await database;
    final now = _nowIso();
    final endedAt = status == 'completed' || status == 'interrupted'
        ? startedAt.add(Duration(seconds: actualSeconds)).toIso8601String()
        : null;

    return await db.insert('pomodoro_sessions', {
      'task_id': taskId,
      'mode': mode,
      'status': status,
      'planned_seconds': plannedSeconds,
      'actual_seconds': actualSeconds,
      'interrupted_at_second': interruptedAtSecond,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt,
      'created_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getSessionsForDate(DateTime date) async {
    final db = await database;
    final d = _dateKey(date);
    return await db.rawQuery(
      "SELECT * FROM pomodoro_sessions WHERE date(started_at) = ? ORDER BY started_at DESC",
      [d],
    );
  }

  Future<List<Map<String, dynamic>>> getSessionsByTask(int taskId) async {
    final db = await database;
    return await db.query(
      'pomodoro_sessions',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'started_at DESC',
    );
  }

  Future<int> getInterruptedCount(DateTime date) async {
    final db = await database;
    final d = _dateKey(date);
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM pomodoro_sessions WHERE date(started_at) = ? AND status = 'interrupted'",
      [d],
    );
    return result.first['c'] as int;
  }

  Future<int> getAbandonedCount(DateTime date) async {
    final db = await database;
    final d = _dateKey(date);
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM pomodoro_sessions WHERE date(started_at) = ? AND status = 'abandoned'",
      [d],
    );
    return result.first['c'] as int;
  }

  // ── Daily Stats ──

  Future<void> upsertDailyStats({
    required DateTime date,
    required int focusSeconds,
    required bool isCompleted,
    required bool isInterrupted,
    required bool isAbandoned,
  }) async {
    final db = await database;
    final d = _dateKey(date);
    final c = isCompleted ? 1 : 0;
    final i = isInterrupted ? 1 : 0;
    final a = isAbandoned ? 1 : 0;

    await db.execute('''
      INSERT OR REPLACE INTO daily_stats (date, total_focus_seconds, completed_sessions, interrupted_sessions, abandoned_sessions)
      VALUES (?, COALESCE((SELECT total_focus_seconds FROM daily_stats WHERE date = ?), 0) + ?,
                  COALESCE((SELECT completed_sessions FROM daily_stats WHERE date = ?), 0) + ?,
                  COALESCE((SELECT interrupted_sessions FROM daily_stats WHERE date = ?), 0) + ?,
                  COALESCE((SELECT abandoned_sessions FROM daily_stats WHERE date = ?), 0) + ?)
    ''', [d, d, focusSeconds, d, c, d, i, d, a]);
  }

  Future<Map<String, dynamic>?> getDailyStats(DateTime date) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT * FROM daily_stats WHERE date = ?',
      [_dateKey(date)],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ── Hourly Distribution ──

  Future<void> upsertHourlyDistribution({
    required DateTime date,
    required int hour,
    required int focusSeconds,
  }) async {
    final db = await database;
    final d = _dateKey(date);

    await db.execute('''
      INSERT OR REPLACE INTO hourly_distribution (date, hour, focus_seconds, sessions_count)
      VALUES (?, ?,
        COALESCE((SELECT focus_seconds FROM hourly_distribution WHERE date = ? AND hour = ?), 0) + ?,
        COALESCE((SELECT sessions_count FROM hourly_distribution WHERE date = ? AND hour = ?), 0) + 1)
    ''', [d, hour, d, hour, focusSeconds, d, hour]);
  }

  Future<List<Map<String, dynamic>>> getHourlyDistribution(DateTime date) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT * FROM hourly_distribution WHERE date = ? ORDER BY hour ASC',
      [_dateKey(date)],
    );
  }

  // ── Multi-dimensional Queries ──

  Future<Map<String, dynamic>> getFocusTimeByTask(int taskId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(actual_seconds), 0) AS total_seconds, COUNT(*) AS session_count FROM pomodoro_sessions WHERE task_id = ? AND mode = 'work' AND status = 'completed'",
      [taskId],
    );
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    return await db.rawQuery(
      'SELECT date, total_focus_seconds, completed_sessions, interrupted_sessions, abandoned_sessions FROM daily_stats WHERE date >= ? AND date <= ? ORDER BY date ASC',
      [_dateKey(monday), _dateKey(sunday)],
    );
  }

  // ── Task-specific queries ──

  Future<int> getTaskTargetMinutes(int taskId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT target_minutes FROM tasks WHERE id = ?', [taskId]);
    return result.isNotEmpty ? result.first['target_minutes'] as int : 25;
  }

  Future<int> getTodayFocusCountForTask(int taskId) async {
    final db = await database;
    final d = _dateKey(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM pomodoro_sessions WHERE task_id = ? AND date(started_at) = ? AND mode = 'work' AND status = 'completed'",
      [taskId, d],
    );
    return result.first['c'] as int;
  }

  Future<int> getTodayFocusSecondsForTask(int taskId) async {
    final db = await database;
    final d = _dateKey(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(actual_seconds), 0) AS s FROM pomodoro_sessions WHERE task_id = ? AND date(started_at) = ? AND mode = 'work' AND status = 'completed'",
      [taskId, d],
    );
    return result.first['s'] as int;
  }

  Future<int> getTodayTotalCompleted() async {
    final db = await database;
    final d = _dateKey(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM pomodoro_sessions WHERE date(started_at) = ? AND mode = 'work' AND status = 'completed'",
      [d],
    );
    return result.first['c'] as int;
  }

  Future<int> getTodayTotalAbandoned() async {
    final db = await database;
    final d = _dateKey(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM pomodoro_sessions WHERE date(started_at) = ? AND mode = 'work' AND status = 'abandoned'",
      [d],
    );
    return result.first['c'] as int;
  }

  Future<Map<String, int>> getLifetimeStats() async {
    final db = await database;
    final r = await db.rawQuery(
      "SELECT COALESCE(SUM(actual_seconds), 0) AS total_seconds, COUNT(*) AS total_sessions, COUNT(DISTINCT date(started_at)) AS total_days FROM pomodoro_sessions WHERE mode = 'work' AND status = 'completed'",
    );
    return {
      'totalSeconds': r.first['total_seconds'] as int,
      'totalSessions': r.first['total_sessions'] as int,
      'totalDays': r.first['total_days'] as int,
    };
  }

  Future<List<Map<String, dynamic>>> getTaskFocusByRange(
      DateTime start, DateTime end) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.task_id, 
        COALESCE(t.title, '未分类') AS title,
        COALESCE(t.sort_order, 0) % 8 AS color_index,
        SUM(p.actual_seconds) AS total_seconds
      FROM pomodoro_sessions p
      LEFT JOIN tasks t ON t.id = p.task_id
      WHERE p.mode = 'work' AND p.status = 'completed'
        AND p.started_at >= ? AND p.started_at <= ?
      GROUP BY p.task_id
      ORDER BY total_seconds DESC
    ''', [start.toIso8601String(), end.add(const Duration(days: 1)).toIso8601String()]);
  }

  // ── Migration ──

  Future<void> migrateFromSharedPreferences(Map<String, int> legacyRecords) async {
    final db = await database;
    for (final entry in legacyRecords.entries) {
      final date = entry.key;
      final count = entry.value;

      final existing = await db.rawQuery('SELECT * FROM daily_stats WHERE date = ?', [date]);
      if (existing.isEmpty) {
        await db.insert('daily_stats', {
          'date': date,
          'total_focus_seconds': count * 25 * 60,
          'completed_sessions': count,
          'interrupted_sessions': 0,
          'abandoned_sessions': 0,
        });
      }
    }
  }

  // ── Test Helpers ──

  Future<void> resetForTest() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('pomodoro_sessions');
    await db.delete('daily_stats');
    await db.delete('hourly_distribution');
  }

  // ── Private helpers ──

  String _nowIso() => DateTime.now().toIso8601String();
  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
