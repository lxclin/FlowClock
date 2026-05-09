import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/utils/vibration_util.dart';
import '../../biometrics/providers/biometrics_provider.dart';
import '../../biometrics/models/mental_state.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/timer_state.dart';

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

  BiometricsNotifier get _bioNotifier =>
      _ref.read(biometricsProvider.notifier);

  BiometricsState get _bioState => _ref.read(biometricsProvider);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final work = prefs.getInt('work_duration') ?? 25 * 60;
    final short = prefs.getInt('short_break_duration') ?? 5 * 60;
    final long = prefs.getInt('long_break_duration') ?? 15 * 60;

    if (mounted) {
      state = state.copyWith(
        totalSeconds: work,
        remainingSeconds: work,
        workDuration: work,
        shortBreakDuration: short,
        longBreakDuration: long,
      );
    }
  }

  int _getDuration(TimerMode mode) {
    switch (mode) {
      case TimerMode.work:
        return state.workDuration;
      case TimerMode.shortBreak:
        return state.shortBreakDuration;
      case TimerMode.longBreak:
        return state.longBreakDuration;
    }
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
    if (state.isRunning) {
      pause();
    } else {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _bioNotifier.stopSession();
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

  void skip() {
    _timer?.cancel();
    _timer = null;
    _bioNotifier.stopSession();
    VibrationUtil.light();
    _switchToNextMode();
  }

  void switchMode(TimerMode mode) {
    _timer?.cancel();
    _timer = null;
    _bioNotifier.stopSession();
    final duration = _getDuration(mode);
    state = state.copyWith(
      mode: mode,
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

  void updateDurations({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
  }) {
    state = state.copyWith(
      workDuration: workDuration ?? state.workDuration,
      shortBreakDuration: shortBreakDuration ?? state.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? state.longBreakDuration,
    );

    if (!state.isRunning) {
      final duration = _getDuration(state.mode);
      state = state.copyWith(
        remainingSeconds: duration,
        totalSeconds: duration,
      );
    }
  }

  void extendWork({int additionalSeconds = 10 * 60}) {
    state = state.copyWith(
      totalSeconds: state.totalSeconds + additionalSeconds,
      remainingSeconds: state.remainingSeconds + additionalSeconds,
      clearPendingAlert: true,
      flowExtensionsUsed: state.flowExtensionsUsed + 1,
    );
    _bioNotifier.resetAlertState();
  }

  void triggerMicroBreak() {
    _timer?.cancel();
    _timer = null;

    state = state.copyWith(
      isRunning: false,
      isMicroBreak: true,
      savedRemainingSeconds: state.remainingSeconds,
      remainingSeconds: 2 * 60,
      totalSeconds: 2 * 60,
      clearPendingAlert: true,
    );

    _bioNotifier.resetAlertState();

    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _microBreakTick());
    state = state.copyWith(isRunning: true);
  }

  void triggerBreathingGuide() {
    _timer?.cancel();
    _timer = null;

    state = state.copyWith(
      isRunning: false,
      isBreathing: true,
      savedRemainingSeconds: state.remainingSeconds,
      remainingSeconds: 3 * 60,
      totalSeconds: 3 * 60,
      clearPendingAlert: true,
    );

    _bioNotifier.resetAlertState();

    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _breathingTick());
    state = state.copyWith(isRunning: true);
  }

  void dismissAlert() {
    state = state.copyWith(clearPendingAlert: true);
    _bioNotifier.resetAlertState();
  }

  void _tick() {
    _tickCount++;

    if (state.mode == TimerMode.work &&
        _bioState.biometricsEnabled &&
        _bioState.isScanning &&
        _tickCount % 30 == 0) {
      final result = _bioNotifier.evaluate(_sessionId);
      if (result != null && mounted) {
        if (result.state == MentalState.flow) {
          state = state.copyWith(pendingAlert: PendingAlertType.flow);
        } else if (result.state == MentalState.fatigue) {
          state = state.copyWith(pendingAlert: PendingAlertType.fatigue);
        }
      }
    }

    if (state.remainingSeconds <= 0) {
      _timer?.cancel();
      _timer = null;
      _handleCompletion();
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  void _microBreakTick() {
    if (state.remainingSeconds <= 0) {
      _timer?.cancel();
      _timer = null;
      _resumeFromMicroBreak();
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  void _breathingTick() {
    if (state.remainingSeconds <= 0) {
      _timer?.cancel();
      _timer = null;
      _resumeFromBreathing();
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  void _resumeFromMicroBreak() {
    final duration = _getDuration(state.mode);
    state = state.copyWith(
      remainingSeconds: state.savedRemainingSeconds,
      totalSeconds: duration,
      isRunning: false,
      isMicroBreak: false,
      savedRemainingSeconds: 0,
    );
  }

  void _resumeFromBreathing() {
    final duration = _getDuration(state.mode);
    state = state.copyWith(
      remainingSeconds: state.savedRemainingSeconds,
      totalSeconds: duration,
      isRunning: false,
      isBreathing: false,
      savedRemainingSeconds: 0,
    );
  }

  void _handleCompletion() {
    final settings = _ref.read(settingsProvider);
    if (settings.vibrationEnabled) {
      VibrationUtil.timerComplete();
    }
    if (settings.soundEnabled) {
      final player = AudioPlayer();
      player.play(AssetSource('assets/audio/complete.wav'));
    }

    if (state.isMicroBreak || state.isBreathing) {
      if (state.isMicroBreak) {
        _resumeFromMicroBreak();
      } else {
        _resumeFromBreathing();
      }
      return;
    }

    final newPomodoros =
        state.mode == TimerMode.work ? state.sessionPomodoros + 1 : state.sessionPomodoros;

    state = state.copyWith(sessionPomodoros: newPomodoros);
    _bioNotifier.stopSession();
    _switchToNextMode();
  }

  void _switchToNextMode() {
    final nextMode = state.mode == TimerMode.work
        ? (state.sessionPomodoros % 4 == 0 ? TimerMode.longBreak : TimerMode.shortBreak)
        : TimerMode.work;

    final nextDuration = _getDuration(nextMode);

    state = state.copyWith(
      mode: nextMode,
      remainingSeconds: nextDuration,
      totalSeconds: nextDuration,
      isRunning: false,
      clearPendingAlert: true,
      flowExtensionsUsed: 0,
      isMicroBreak: false,
      isBreathing: false,
      savedRemainingSeconds: 0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _bioNotifier.stopSession();
    } catch (_) {}
    super.dispose();
  }
}
