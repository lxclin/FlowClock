enum TimerMode { work, rest }

extension TimerModeX on TimerMode {
  String get label {
    switch (this) {
      case TimerMode.work:
        return '专注';
      case TimerMode.rest:
        return '休息';
    }
  }

  String get icon {
    switch (this) {
      case TimerMode.work:
        return '🍅';
      case TimerMode.rest:
        return '☕';
    }
  }
}

enum PendingAlertType { flow, fatigue }

class TimerState {
  final TimerMode mode;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final int sessionPomodoros;
  final int workDuration;
  final int breakDuration;
  final PendingAlertType? pendingAlert;
  final int flowExtensionsUsed;
  final bool isMicroBreak;
  final bool isBreathing;
  final int savedRemainingSeconds;

  const TimerState({
    required this.mode,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.sessionPomodoros,
    this.workDuration = 25 * 60,
    this.breakDuration = 5 * 60,
    this.pendingAlert,
    this.flowExtensionsUsed = 0,
    this.isMicroBreak = false,
    this.isBreathing = false,
    this.savedRemainingSeconds = 0,
  });

  double get progress {
    if (totalSeconds == 0) return 0;
    return 1.0 - (remainingSeconds / totalSeconds);
  }

  TimerState copyWith({
    TimerMode? mode,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    int? sessionPomodoros,
    int? workDuration,
    int? breakDuration,
    PendingAlertType? pendingAlert,
    bool clearPendingAlert = false,
    int? flowExtensionsUsed,
    bool? isMicroBreak,
    bool? isBreathing,
    int? savedRemainingSeconds,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionPomodoros: sessionPomodoros ?? this.sessionPomodoros,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      pendingAlert: clearPendingAlert ? null : (pendingAlert ?? this.pendingAlert),
      flowExtensionsUsed: flowExtensionsUsed ?? this.flowExtensionsUsed,
      isMicroBreak: isMicroBreak ?? this.isMicroBreak,
      isBreathing: isBreathing ?? this.isBreathing,
      savedRemainingSeconds: savedRemainingSeconds ?? this.savedRemainingSeconds,
    );
  }
}
