import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../providers/ambient_sound_provider.dart';
import '../../stats/providers/stats_provider.dart';
import '../widgets/circular_progress.dart';
import 'breathing_guide_page.dart';
import 'flow_extension_dialog.dart';
import 'fatigue_alert_dialog.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final statsState = ref.watch(statsProvider);
    final ambientSound = ref.watch(ambientSoundProvider);

    ref.listen<TimerState>(timerProvider, (previous, next) {
      if (next.pendingAlert == PendingAlertType.flow &&
          previous?.pendingAlert != PendingAlertType.flow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FlowExtensionDialog.show(context);
          }
        });
      } else if (next.pendingAlert == PendingAlertType.fatigue &&
          previous?.pendingAlert != PendingAlertType.fatigue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FatigueAlertDialog.show(context);
          }
        });
      }
    });

    if (timerState.isBreathing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showBreathingGuide(context);
        }
      });
    }

    if (timerState.isMicroBreak) {
      return _buildMicroBreakUI(timerState);
    }

    final currentColor = timerState.mode == TimerMode.work
        ? AppTheme.workColor
        : AppTheme.breakColor;
    final bgColor = timerState.mode == TimerMode.work
        ? AppTheme.workBackground
        : AppTheme.breakBackground;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor, Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _TopBar(
              ambientSound: ambientSound,
              onAmbientTap: () => _showAmbientSheet(context),
              todayCount: statsState.todayCount,
            ),
            const SizedBox(height: 12),
            _ModeSelector(ref: ref, timerState: timerState),
            const Spacer(flex: 1),
            CircularProgress(
              progress: timerState.progress,
              progressColor: currentColor,
              centerChild: _TimeDisplay(
                remainingSeconds: timerState.remainingSeconds,
                currentColor: currentColor,
              ),
              label: timerState.mode.label,
            ),
            const SizedBox(height: 12),
            Text(
              '第 ${timerState.sessionPomodoros} / 4 个番茄',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (timerState.flowExtensionsUsed > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '已延长 ${timerState.flowExtensionsUsed} 次',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.workColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _ControlButtons(ref: ref, timerState: timerState, currentColor: currentColor),
            const Spacer(flex: 1),
            if (ambientSound != AmbientSound.none)
              _NowPlaying(
                sound: ambientSound,
                onTap: () => ref.read(ambientSoundProvider.notifier).stop(),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroBreakUI(TimerState timerState) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.breakBackground, Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              '😌',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            const Text(
              '微休息',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '放松眼睛，伸展身体\n两分钟后自动恢复工作',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const Spacer(),
            CircularProgress(
              progress: timerState.progress,
              progressColor: AppTheme.breakColor,
              centerChild: _TimeDisplay(
                remainingSeconds: timerState.remainingSeconds,
                currentColor: AppTheme.breakColor,
              ),
              label: '微休息',
            ),
            const Spacer(flex: 2),
            TextButton(
              onPressed: () {
                ref.read(timerProvider.notifier).reset();
              },
              child: const Text(
                '感觉好了，回到工作',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.breakColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showBreathingGuide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const BreathingGuidePage()),
    );
  }

  void _showAmbientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AmbientSoundSheet(),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AmbientSound ambientSound;
  final VoidCallback onAmbientTap;
  final int todayCount;

  const _TopBar({
    required this.ambientSound,
    required this.onAmbientTap,
    required this.todayCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.workColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '今日 $todayCount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAmbientTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ambientSound != AmbientSound.none
                    ? AppTheme.breakColor.withValues(alpha: 0.15)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ambientSound != AmbientSound.none
                        ? ambientSound.icon
                        : '🎵',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ambientSound != AmbientSound.none
                        ? ambientSound.label
                        : '环境音',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ambientSound != AmbientSound.none
                          ? AppTheme.breakColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  final AmbientSound sound;
  final VoidCallback onTap;

  const _NowPlaying({required this.sound, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.breakColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sound.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '正在播放: ${sound.label}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.breakColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.stop_circle_outlined,
                size: 16, color: AppTheme.breakColor),
          ],
        ),
      ),
    );
  }
}

class _AmbientSoundSheet extends ConsumerWidget {
  const _AmbientSoundSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(ambientSoundProvider);
    const sounds = AmbientSound.values;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择环境音',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '帮助集中注意力，营造专注氛围',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ...sounds.map((sound) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    ref.read(ambientSoundProvider.notifier).setSound(sound);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: current == sound
                          ? AppTheme.breakColor.withValues(alpha: 0.1)
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: current == sound
                          ? Border.all(
                              color: AppTheme.breakColor.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(sound.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(
                          sound.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: current == sound
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (current == sound)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.breakColor,
                            ),
                            child: const Icon(Icons.check,
                                size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 12),
          if (current != AmbientSound.none) ...[
            const Text('音量', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: AppTheme.breakColor,
                inactiveTrackColor: AppTheme.trackColor,
                thumbColor: AppTheme.breakColor,
                overlayColor: AppTheme.breakColor.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: 0.3,
                min: 0.05,
                max: 1.0,
                onChanged: (v) =>
                    ref.read(ambientSoundProvider.notifier).setVolume(v),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final WidgetRef ref;
  final TimerState timerState;

  const _ModeSelector({required this.ref, required this.timerState});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeChip(
          label: '🍅 专注',
          isSelected: timerState.mode == TimerMode.work,
          color: AppTheme.workColor,
          onTap: () =>
              ref.read(timerProvider.notifier).switchMode(TimerMode.work),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: '☕ 短休息',
          isSelected: timerState.mode == TimerMode.shortBreak,
          color: AppTheme.breakColor,
          onTap: () =>
              ref.read(timerProvider.notifier).switchMode(TimerMode.shortBreak),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: '🌿 长休息',
          isSelected: timerState.mode == TimerMode.longBreak,
          color: AppTheme.breakColor,
          onTap: () =>
              ref.read(timerProvider.notifier).switchMode(TimerMode.longBreak),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.trackColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final int remainingSeconds;
  final Color currentColor;

  const _TimeDisplay({
    required this.remainingSeconds,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        color: AppTheme.textPrimary,
        letterSpacing: 4,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final WidgetRef ref;
  final TimerState timerState;
  final Color currentColor;

  const _ControlButtons({
    required this.ref,
    required this.timerState,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(timerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.refresh_rounded,
          size: 56,
          color: AppTheme.textSecondary,
          onTap: () => notifier.reset(),
        ),
        const SizedBox(width: 24),
        _CircleButton(
          icon: timerState.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 72,
          color: currentColor,
          isMain: true,
          onTap: () => notifier.toggle(),
        ),
        const SizedBox(width: 24),
        _CircleButton(
          icon: Icons.skip_next_rounded,
          size: 56,
          color: AppTheme.textSecondary,
          onTap: () => notifier.skip(),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool isMain;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.size,
    required this.color,
    this.isMain = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMain ? color : Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isMain ? 0.3 : 0.1),
              blurRadius: isMain ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isMain ? Colors.white : color,
          size: size * 0.45,
        ),
      ),
    );
  }
}
