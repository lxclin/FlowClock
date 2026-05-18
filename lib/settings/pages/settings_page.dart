import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../timer/providers/timer_provider.dart';
import '../../biometrics/providers/biometrics_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Container(
      color: AppTheme.bgCream,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('设置', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 28),
              const _SectionTitle(title: '休息时长'),
              const SizedBox(height: 12),
              _DurationSlider(
                label: '休息时长',
                icon: Icons.coffee_rounded,
                color: AppTheme.breakColor,
                seconds: settings.breakDuration,
                onChanged: (v) {
                  ref.read(settingsProvider.notifier).setBreakDuration(v);
                  ref.read(timerProvider.notifier).updateDurations(breakDuration: v);
                },
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: '自适应专注'),
              const SizedBox(height: 12),
              _ToggleTile(
                icon: Icons.monitor_heart_rounded,
                label: '生物识别（心率/HRV）',
                subtitle: '基于心率/HRV动态调整计时策略',
                value: ref.watch(biometricsProvider).biometricsEnabled,
                onChanged: (v) => ref.read(biometricsProvider.notifier).setBiometricsEnabled(v),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: '偏好设置'),
              const SizedBox(height: 12),
              _ToggleTile(
                icon: Icons.volume_up_rounded,
                label: '完成提示音',
                subtitle: null,
                value: settings.soundEnabled,
                onChanged: (_) => ref.read(settingsProvider.notifier).toggleSound(),
              ),
              _ToggleTile(
                icon: Icons.vibration_rounded,
                label: '完成震动',
                subtitle: null,
                value: settings.vibrationEnabled,
                onChanged: (_) => ref.read(settingsProvider.notifier).toggleVibration(),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: '关于'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(20)),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FlowClock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  SizedBox(height: 6),
                  Text('Version 1.1.0\nBuilt with Flutter & Riverpod\nAuthor: lxclin\nAI-assisted Vibe Coding project',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6)),
                ]),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1));
}

class _DurationSlider extends StatelessWidget {
  final String label; final IconData icon; final Color color; final int seconds; final ValueChanged<int> onChanged;
  const _DurationSlider({required this.label, required this.icon, required this.color, required this.seconds, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20), const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Spacer(),
              Text('$minutes分钟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
        SliderTheme(
          data: SliderThemeData(trackHeight: 6, activeTrackColor: color, inactiveTrackColor: AppTheme.trackColor, thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15), thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10)),
          child: Slider(value: minutes.toDouble(), min: 1, max: 60, divisions: 59, onChanged: (v) => onChanged(v.round() * 60)),
        ),
      ]),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon; final String label; final String? subtitle; final bool value; final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: AppTheme.textPrimary, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        value: value, onChanged: onChanged, activeTrackColor: AppTheme.workColor,
      ),
    );
  }
}
