import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.workDuration = 25 * 60,
    this.shortBreakDuration = 5 * 60,
    this.longBreakDuration = 15 * 60,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      state = SettingsState(
        workDuration: prefs.getInt('work_duration') ?? 25 * 60,
        shortBreakDuration: prefs.getInt('short_break_duration') ?? 5 * 60,
        longBreakDuration: prefs.getInt('long_break_duration') ?? 15 * 60,
        soundEnabled: prefs.getBool('sound_enabled') ?? true,
        vibrationEnabled: prefs.getBool('vibration_enabled') ?? true,
      );
    }
  }

  Future<void> setWorkDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('work_duration', seconds);
    state = state.copyWith(workDuration: seconds);
  }

  Future<void> setShortBreakDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('short_break_duration', seconds);
    state = state.copyWith(shortBreakDuration: seconds);
  }

  Future<void> setLongBreakDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('long_break_duration', seconds);
    state = state.copyWith(longBreakDuration: seconds);
  }

  Future<void> toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.soundEnabled;
    await prefs.setBool('sound_enabled', newValue);
    state = state.copyWith(soundEnabled: newValue);
  }

  Future<void> toggleVibration() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.vibrationEnabled;
    await prefs.setBool('vibration_enabled', newValue);
    state = state.copyWith(vibrationEnabled: newValue);
  }
}
