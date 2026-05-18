import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../providers/ambient_sound_provider.dart';
import '../../todo/providers/task_provider.dart';
import '../providers/active_task_provider.dart';
import '../../stats/providers/session_provider.dart';
import '../../stats/providers/stats_provider.dart';
import '../widgets/circular_progress.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  DateTime? _sessionStart;
  int _sessionPlannedSeconds = 0;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_autoStarted) {
        _autoStarted = true;
        _sessionStart = DateTime.now();
        _sessionPlannedSeconds = ref.read(timerProvider).remainingSeconds;
        ref.read(timerProvider.notifier).start();
      }
    });
  }

  void _abandonSession() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('放弃当前番茄？'),
        content: const Text('已专注的时间会被记录为"放弃"。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('继续专注')),
          TextButton(
            onPressed: () {
              final taskId = ref.read(activeTaskIdProvider);
              final timerState = ref.read(timerProvider);
              final elapsed = _sessionPlannedSeconds - timerState.remainingSeconds;
              final start = _sessionStart ?? DateTime.now().subtract(Duration(seconds: elapsed));

              SessionRecorder.recordAbandoned(
                taskId: taskId,
                mode: 'work',
                plannedSeconds: _sessionPlannedSeconds,
                actualSeconds: elapsed.clamp(0, _sessionPlannedSeconds),
                startedAt: start,
              );
              ref.read(timerProvider.notifier).pause();
              Navigator.pop(context); // dialog
              Navigator.pop(context); // fullscreen timer
            },
            child: const Text('放弃', style: TextStyle(color: AppTheme.workColor)),
          ),
        ],
      ),
    );
  }

  void _showAmbientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final sounds = AmbientSound.values;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('选择环境音', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('帮助集中注意力，营造专注氛围', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            for (final sound in sounds)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Consumer(
                  builder: (_, ref, __) {
                    final current = ref.watch(ambientSoundProvider);
                    final selected = current == sound;
                    return GestureDetector(
                      onTap: () {
                        ref.read(ambientSoundProvider.notifier).setSound(sound);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.breakColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: selected ? Border.all(color: AppTheme.breakColor.withValues(alpha: 0.3)) : null,
                        ),
                        child: Row(children: [
                          Text(sound.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(sound.label, style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: AppTheme.textPrimary)),
                          const Spacer(),
                          if (selected) Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.breakColor), child: const Icon(Icons.check, size: 14, color: Colors.white)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final ambientSound = ref.watch(ambientSoundProvider);
    final activeTaskId = ref.watch(activeTaskIdProvider);
    final tasks = ref.watch(taskProvider);
    final activeTask = activeTaskId != null
        ? [...tasks.active, ...tasks.archived].where((t) => t.id == activeTaskId).firstOrNull
        : null;
    final currentColor = timerState.mode == TimerMode.work
        ? AppTheme.workColor
        : AppTheme.breakColor;
    final bgColor = timerState.mode == TimerMode.work
        ? AppTheme.workBackground
        : AppTheme.breakBackground;

    // work completes → auto-start rest
    ref.listen(timerProvider, (prev, next) {
      if (prev != null &&
          prev.mode == TimerMode.work &&
          next.mode == TimerMode.rest &&
          next.sessionPomodoros > prev.sessionPomodoros &&
          !next.isRunning) {
        ref.read(timerProvider.notifier).autoStartRest();
      }
    });

    // Fix 2: rest completes → record + pop
    ref.listen(timerProvider, (prev, next) {
      if (prev != null &&
          prev.mode == TimerMode.rest &&
          next.mode == TimerMode.work &&
          prev.isRunning &&
          !next.isRunning &&
          next.sessionPomodoros == prev.sessionPomodoros) {
        final planned = prev.totalSeconds;
        final start = DateTime.now().subtract(Duration(seconds: planned));
        SessionRecorder.recordCompleted(
          taskId: ref.read(activeTaskIdProvider),
          mode: 'rest',
          plannedSeconds: planned,
          actualSeconds: planned,
          startedAt: start,
        );
        if (mounted) Navigator.of(context).pop();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _abandonSession();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
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
                _TopBar(ambientSound: ambientSound, onAmbientTap: () => _showAmbientSheet(context), activeTaskTitle: activeTask?.title),
                const Spacer(flex: 1),
                CircularProgress(
                  progress: timerState.progress,
                  progressColor: currentColor,
                  centerChild: _TimeDisplay(remainingSeconds: timerState.remainingSeconds),
                  label: timerState.mode.label,
                ),
                const SizedBox(height: 12),
                Text('已完成 ${timerState.sessionPomodoros} 个番茄',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                _ControlButtons(ref: ref, timerState: timerState, currentColor: currentColor),
                const Spacer(flex: 1),
                _AbandonButton(onTap: _abandonSession),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AmbientSound ambientSound;
  final VoidCallback onAmbientTap;
  final String? activeTaskTitle;

  const _TopBar({required this.ambientSound, required this.onAmbientTap, this.activeTaskTitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          if (activeTaskTitle != null)
            Flexible(
              child: Text('🔘 $activeTaskTitle',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
          const Spacer(),
          GestureDetector(
            onTap: onAmbientTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ambientSound != AmbientSound.none ? AppTheme.breakColor.withValues(alpha: 0.15) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(ambientSound != AmbientSound.none ? ambientSound.icon : '🎵', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(ambientSound != AmbientSound.none ? ambientSound.label : '环境音',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: ambientSound != AmbientSound.none ? AppTheme.breakColor : AppTheme.textSecondary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbandonButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AbandonButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.workColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.workColor.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Text('🚪 放弃当前番茄',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.workColor)),
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final int remainingSeconds;
  const _TimeDisplay({required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final display = minutes >= 100
        ? '${minutes}m${seconds.toString().padLeft(2, '0')}s'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Text(display,
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: AppTheme.textPrimary,
            letterSpacing: 2, fontFeatures: [FontFeature.tabularFigures()]));
  }
}

class _ControlButtons extends StatelessWidget {
  final WidgetRef ref;
  final TimerState timerState;
  final Color currentColor;

  const _ControlButtons({required this.ref, required this.timerState, required this.currentColor});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(timerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(icon: Icons.refresh_rounded, size: 56, color: AppTheme.textSecondary,
            onTap: () => notifier.reset()),
        const SizedBox(width: 24),
        _CircleButton(
            icon: timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 72, color: currentColor, isMain: true,
            onTap: () => notifier.toggle()),
        const SizedBox(width: 24),
        _CircleButton(icon: Icons.skip_next_rounded, size: 56, color: AppTheme.textSecondary,
            onTap: () => notifier.skip()),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon; final double size; final Color color; final bool isMain; final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.size, required this.color, this.isMain = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMain ? color : Colors.white,
          boxShadow: [BoxShadow(color: color.withValues(alpha: isMain ? 0.3 : 0.1), blurRadius: isMain ? 16 : 8, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: isMain ? Colors.white : color, size: size * 0.45),
      ),
    );
  }
}
