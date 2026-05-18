import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier();
});

class StatsState {
  final int todayFocusSeconds;
  final int todayCompleted;
  final int todayInterrupted;
  final int todayAbandoned;
  final int totalFocusSeconds;
  final int totalSessions;
  final List<Map<String, dynamic>> weeklyStats;
  final List<Map<String, dynamic>> hourlyDistribution;
  final List<Map<String, dynamic>> taskFocusData;
  final bool isLoading;

  const StatsState({
    this.todayFocusSeconds = 0,
    this.todayCompleted = 0,
    this.todayInterrupted = 0,
    this.todayAbandoned = 0,
    this.totalFocusSeconds = 0,
    this.totalSessions = 0,
    this.weeklyStats = const [],
    this.hourlyDistribution = const [],
    this.taskFocusData = const [],
    this.isLoading = true,
  });

  StatsState copyWith({
    int? todayFocusSeconds,
    int? todayCompleted,
    int? todayInterrupted,
    int? todayAbandoned,
    int? totalFocusSeconds,
    int? totalSessions,
    List<Map<String, dynamic>>? weeklyStats,
    List<Map<String, dynamic>>? hourlyDistribution,
    List<Map<String, dynamic>>? taskFocusData,
    bool? isLoading,
  }) {
    return StatsState(
      todayFocusSeconds: todayFocusSeconds ?? this.todayFocusSeconds,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      todayInterrupted: todayInterrupted ?? this.todayInterrupted,
      todayAbandoned: todayAbandoned ?? this.todayAbandoned,
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      totalSessions: totalSessions ?? this.totalSessions,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      hourlyDistribution: hourlyDistribution ?? this.hourlyDistribution,
      taskFocusData: taskFocusData ?? this.taskFocusData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier() : super(const StatsState()) {
    refresh();
  }

  Future<void> refresh() async {
    final now = DateTime.now();
    final today = await DatabaseHelper.instance.getDailyStats(now);
    final weekly = await DatabaseHelper.instance.getWeeklyStats();
    final hourly = await DatabaseHelper.instance.getHourlyDistribution(now);

    int totalFocus = 0;
    int totalSessions = 0;
    for (final w in weekly) {
      totalFocus += (w['total_focus_seconds'] as int);
      totalSessions += (w['completed_sessions'] as int);
    }

    if (mounted) {
      state = state.copyWith(
        todayFocusSeconds: today?['total_focus_seconds'] as int? ?? 0,
        todayCompleted: today?['completed_sessions'] as int? ?? 0,
        todayInterrupted: today?['interrupted_sessions'] as int? ?? 0,
        todayAbandoned: today?['abandoned_sessions'] as int? ?? 0,
        totalFocusSeconds: totalFocus,
        totalSessions: totalSessions,
        weeklyStats: weekly,
        hourlyDistribution: hourly,
        isLoading: false,
      );
    }
  }

  Future<void> updateWorkDuration(int seconds) async {
    // Stored in settings; actual stats use session data from DB.
  }
}
