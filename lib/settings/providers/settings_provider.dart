import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final int workDuration;
  final int breakDuration;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.workDuration = 25 * 60,
    this.breakDuration = 5 * 60,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    int? workDuration,
    int? breakDuration,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
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
        breakDuration: prefs.getInt('break_duration') ?? 5 * 60,
        soundEnabled: prefs.getBool('sound_enabled') ?? true,
        vibrationEnabled: prefs.getBool('vibration_enabled') ?? true,
      );
    }
  }

  Future<void> setBreakDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('break_duration', seconds);
    state = state.copyWith(breakDuration: seconds);
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
