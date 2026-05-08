import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/pomodoro_record.dart';

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier();
});

class StatsState {
  final int todayCount;
  final int totalMinutes;
  final Map<String, int> dailyRecords;
  final int workDurationSeconds;

  const StatsState({
    this.todayCount = 0,
    this.totalMinutes = 0,
    this.dailyRecords = const {},
    this.workDurationSeconds = 25 * 60,
  });

  StatsState copyWith({
    int? todayCount,
    int? totalMinutes,
    Map<String, int>? dailyRecords,
    int? workDurationSeconds,
  }) {
    return StatsState(
      todayCount: todayCount ?? this.todayCount,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      dailyRecords: dailyRecords ?? this.dailyRecords,
      workDurationSeconds: workDurationSeconds ?? this.workDurationSeconds,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier() : super(const StatsState()) {
    _loadStats();
  }

  static String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList('pomodoro_records') ?? [];
    final totalMinutes = prefs.getInt('total_focus_minutes') ?? 0;
    final workDuration = prefs.getInt('work_duration') ?? 25 * 60;

    final Map<String, int> dailyMap = {};
    for (final record in records) {
      final parts = record.split(':');
      if (parts.length == 2) {
        dailyMap[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }

    final todayCount = dailyMap[_todayKey] ?? 0;

    if (mounted) {
      state = StatsState(
        todayCount: todayCount,
        totalMinutes: totalMinutes,
        dailyRecords: dailyMap,
        workDurationSeconds: workDuration,
      );
    }
  }

  Future<void> incrementPomodoro() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey;

    final newDailyRecords = Map<String, int>.from(state.dailyRecords);
    newDailyRecords[todayKey] = (newDailyRecords[todayKey] ?? 0) + 1;

    final recordsList = newDailyRecords.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();

    final minutesPerPomodoro = state.workDurationSeconds ~/ 60;
    final newTotalMinutes = state.totalMinutes + minutesPerPomodoro;

    await prefs.setStringList('pomodoro_records', recordsList);
    await prefs.setInt('total_focus_minutes', newTotalMinutes);

    if (mounted) {
      state = state.copyWith(
        todayCount: newDailyRecords[todayKey]!,
        totalMinutes: newTotalMinutes,
        dailyRecords: newDailyRecords,
      );
    }
  }

  List<DateTime> getWeekDates() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return DateTime(date.year, date.month, date.day);
    });
  }

  int getCountForDate(DateTime date) {
    final key = PomodoroRecord.formatDate(date);
    return state.dailyRecords[key] ?? 0;
  }

  Future<void> updateWorkDuration(int seconds) async {
    if (mounted) {
      state = state.copyWith(workDurationSeconds: seconds);
    }
  }
}
