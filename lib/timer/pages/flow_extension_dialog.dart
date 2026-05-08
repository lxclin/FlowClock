import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/timer_provider.dart';

class FlowExtensionDialog extends ConsumerWidget {
  const FlowExtensionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text('🧠', style: TextStyle(fontSize: 28)),
          SizedBox(width: 10),
          Text(
            '检测到心流状态',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: const Text(
        '您当前处于高效专注状态。\n\n心率平稳上升，HRV保持高位 — 这是最佳工作状态的生理信号。\n\n是否延长专注时间？',
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
            '不需要',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () {
            ref.read(timerProvider.notifier).extendWork();
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.workColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('+10 分钟', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FlowExtensionDialog(),
    );
  }
}
