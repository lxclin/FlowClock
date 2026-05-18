import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/utils/vibration_util.dart';
import '../../biometrics/providers/biometrics_provider.dart';
import '../../biometrics/models/mental_state.dart';
import '../../stats/providers/session_provider.dart';
import '../../stats/providers/stats_provider.dart';
import '../../todo/providers/task_provider.dart';
import '../models/timer_state.dart';
import 'active_task_provider.dart';

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});

class TimerNotifier extends StateNotifier<TimerState> {
  final Ref _ref;
  Timer? _timer;
  int _tickCount = 0;
  String _sessionId = '';

  TimerNotifier(this._ref)
      : super(const TimerState(
          mode: TimerMode.work,
          remainingSeconds: 25 * 60,
          totalSeconds: 25 * 60,
          isRunning: false,
          sessionPomodoros: 0,
        )) {
    _loadSettings();
  }

  BiometricsNotifier get _bioNotifier => _ref.read(biometricsProvider.notifier);
  BiometricsState get _bioState => _ref.read(biometricsProvider);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final brk = prefs.getInt('break_duration') ?? 5 * 60;
    if (mounted) {
      state = state.copyWith(breakDuration: brk);
    }
  }

  int _getDuration(TimerMode mode) {
    return mode == TimerMode.work ? state.workDuration : state.breakDuration;
  }

  void start() {
    if (state.isRunning) return;
    _timer?.cancel();
    _tickCount = 0;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (state.mode == TimerMode.work && _bioState.biometricsEnabled) {
      _bioNotifier.startSession(_sessionId);
    }
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _bioNotifier.stopSession();
    state = state.copyWith(isRunning: false);
  }

  void toggle() {
    state.isRunning ? pause() : start();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    final duration = _getDuration(state.mode);
    state = state.copyWith(
      remainingSeconds: duration,
      totalSeconds: duration,
      isRunning: false,
      clearPendingAlert: true,
      flowExtensionsUsed: 0,
      isMicroBreak: false,
      isBreathing: false,
      savedRemainingSeconds: 0,
    );
  }

  void resetToWorkWithDuration(int seconds) {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      mode: TimerMode.work,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      workDuration: seconds,
      isRunning: false,
      clearPendingAlert: true,
      flowExtensionsUsed: 0,
      isMicroBreak: false,
      isBreathing: false,
      savedRemainingSeconds: 0,
    );
  }

  void resetToWork() {
    final duration = state.workDuration;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      mode: TimerMode.work,
      remainingSeconds: duration,
      totalSeconds: duration,
      isRunning: false,
      clearPendingAlert: true,
      flowExtensionsUsed: 0,
      isMicroBreak: false,
      isBreathing: false,
      savedRemainingSeconds: 0,
    );
  }

  void skip() {
    _timer?.cancel();
    _timer = null;
    VibrationUtil.light();
    _switchToNextMode();
  }

  void switchMode(TimerMode mode) {
    _timer?.cancel();
    _timer = null;
    final duration = _getDuration(mode);
    state = state.copyWith(
      mode: mode,
      remainingSeconds: duration,
      totalSeconds: duration,
      isRunning: false,
    );
  }

  void updateDurations({int? workDuration, int? breakDuration}) {
    state = state.copyWith(
      workDuration: workDuration ?? state.workDuration,
      breakDuration: breakDuration ?? state.breakDuration,
    );
    if (!state.isRunning) {
      final duration = _getDuration(state.mode);
      state = state.copyWith(remainingSeconds: duration, totalSeconds: duration);
    }
  }

  void _tick() {
    if (state.remainingSeconds <= 0) {
      _timer?.cancel();
      _timer = null;
      _handleCompletion();
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  void _handleCompletion() async {
    VibrationUtil.timerComplete();
    _playCompletionSound();

    final isWork = state.mode == TimerMode.work;
    final newPomodoros = isWork ? state.sessionPomodoros + 1 : state.sessionPomodoros;
    final nextMode = isWork ? TimerMode.rest : TimerMode.work;
    final nextDuration = _getDuration(nextMode);
    final completedSeconds = state.totalSeconds;

    if (isWork) {
      final taskId = _ref.read(activeTaskIdProvider);
      final start = DateTime.now().subtract(Duration(seconds: completedSeconds));
      try {
        await SessionRecorder.recordCompleted(
          taskId: taskId,
          mode: 'work',
          plannedSeconds: completedSeconds,
          actualSeconds: completedSeconds,
          startedAt: start,
        );
        if (taskId != null) {
          await _ref.read(taskProvider.notifier).incrementPomodoro(taskId);
        }
        await _ref.read(statsProvider.notifier).refresh();
      } catch (_) {}
    }

    if (mounted) {
      state = state.copyWith(
        mode: nextMode,
        remainingSeconds: nextDuration,
        totalSeconds: nextDuration,
        isRunning: false,
        sessionPomodoros: newPomodoros,
      );
    }
  }

  void _switchToNextMode() {
    final nextMode = state.mode == TimerMode.work ? TimerMode.rest : TimerMode.work;
    final nextDuration = _getDuration(nextMode);
    state = state.copyWith(
      mode: nextMode,
      remainingSeconds: nextDuration,
      totalSeconds: nextDuration,
      isRunning: false,
    );
  }

  void autoStartRest() {
    if (state.mode == TimerMode.rest && !state.isRunning) {
      start();
    }
  }

  void _playCompletionSound() async {
    try {
      final player = AudioPlayer();
      await player.setVolume(0.8);
      await player.play(AssetSource('assets/audio/complete.wav'));
    } catch (_) {
      // Silently ignore if audio not available
    }
  }

  // Biometric alert stubs — preserved for dialog compatibility
  void dismissAlert() {}
  void triggerMicroBreak() {}
  void triggerBreathingGuide() {}
  void extendWork() {}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
