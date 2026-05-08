import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/timer_provider.dart';

class FatigueAlertDialog extends ConsumerWidget {
  const FatigueAlertDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text('😮‍💨', style: TextStyle(fontSize: 28)),
          SizedBox(width: 10),
          Text(
            '检测到疲劳信号',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: const Text(
        '您的HRV出现显著下降，心率异常波动 — 这是身体发出的疲劳信号。\n\n现在休息片刻会比硬撑更高效。',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(timerProvider.notifier).dismissAlert();
            Navigator.pop(context);
          },
          child: const Text(
            '继续工作',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () {
            ref.read(timerProvider.notifier).triggerMicroBreak();
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.breakColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '微休息 2分钟',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () {
            ref.read(timerProvider.notifier).triggerBreathingGuide();
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.breakColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '正念呼吸 3分钟',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FatigueAlertDialog(),
    );
  }
}
