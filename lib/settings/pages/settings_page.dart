import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../timer/providers/timer_provider.dart';
import '../../stats/providers/stats_provider.dart';
import '../../biometrics/providers/biometrics_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final biometrics = ref.watch(biometricsProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.breakBackground, Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                '设置',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: '计时时长'),
              const SizedBox(height: 12),
              _DurationSlider(
                label: '专注时长',
                icon: Icons.work_rounded,
                color: AppTheme.workColor,
                seconds: settings.workDuration,
                onChanged: (v) {
                  ref.read(settingsProvider.notifier).setWorkDuration(v);
                  ref.read(timerProvider.notifier).updateDurations(workDuration: v);
                  ref.read(statsProvider.notifier).updateWorkDuration(v);
                },
              ),
              const SizedBox(height: 8),
              _DurationSlider(
                label: '短休息时长',
                icon: Icons.coffee_rounded,
                color: AppTheme.breakColor,
                seconds: settings.shortBreakDuration,
                onChanged: (v) {
                  ref.read(settingsProvider.notifier).setShortBreakDuration(v);
                  ref.read(timerProvider.notifier).updateDurations(shortBreakDuration: v);
                },
              ),
              const SizedBox(height: 8),
              _DurationSlider(
                label: '长休息时长',
                icon: Icons.self_improvement_rounded,
                color: AppTheme.breakColor,
                seconds: settings.longBreakDuration,
                onChanged: (v) {
                  ref.read(settingsProvider.notifier).setLongBreakDuration(v);
                  ref.read(timerProvider.notifier).updateDurations(longBreakDuration: v);
                },
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: '自适应专注'),
              const SizedBox(height: 12),
              _ToggleTile(
                icon: Icons.monitor_heart_rounded,
                label: '生理感知自适应',
                subtitle: '基于心率/HRV动态调整计时策略',
                value: biometrics.biometricsEnabled,
                onChanged: (v) {
                  ref.read(biometricsProvider.notifier).setBiometricsEnabled(v);
                },
              ),
              if (biometrics.biometricsEnabled) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.workColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: AppTheme.workColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '重新校准基线',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              biometrics.isCalibrated
                                  ? '上次校准: ${biometrics.baseline?.calibratedAt.toString().substring(0, 16) ?? "-"}'
                                  : '尚未校准',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const _SectionTitle(title: '偏好设置'),
              const SizedBox(height: 12),
              _ToggleTile(
                icon: Icons.volume_up_rounded,
                label: '完成提示音',
                value: settings.soundEnabled,
                onChanged: (_) => ref.read(settingsProvider.notifier).toggleSound(),
              ),
              _ToggleTile(
                icon: Icons.vibration_rounded,
                label: '完成震动',
                value: settings.vibrationEnabled,
                onChanged: (_) => ref.read(settingsProvider.notifier).toggleVibration(),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: '关于'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FlowClock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '版本 1.0.0\n基于 Flutter & Riverpod 构建\n一款极简番茄钟，提升你的专注效率。\n\n作者：lxclin',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
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
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 1,
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int seconds;
  final ValueChanged<int> onChanged;

  const _DurationSlider({
    required this.label,
    required this.icon,
    required this.color,
    required this.seconds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                  '$minutes分钟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: color,
              inactiveTrackColor: AppTheme.trackColor,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: minutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: (v) => onChanged(v.round() * 60),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        secondary: Icon(icon, color: AppTheme.textPrimary, size: 22),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              )
            : null,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.workColor,
      ),
    );
  }
}
