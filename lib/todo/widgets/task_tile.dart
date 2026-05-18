import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final bool isActive;
  final int todayFocusCount;
  final int todayFocusSeconds;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onLongPress;

  const TaskTile({
    super.key,
    required this.task,
    required this.isActive,
    required this.todayFocusCount,
    required this.todayFocusSeconds,
    required this.onTap,
    required this.onStart,
    required this.onLongPress,
  });

  Color get _cardAccent => AppTheme.taskAccentColors[task.sortOrder % 8];

  @override
  Widget build(BuildContext context) {
    final gradientColors = AppTheme.taskGradients[task.sortOrder % 8];
    final minutes = todayFocusSeconds ~/ 60;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _cardAccent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${task.title}  🍅 ${task.completedPomodoros}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '今日专注 $todayFocusCount 次 · 共 $minutes 分钟  |  ⏱ ${task.targetMinutes}分钟/次',
                          style: TextStyle(
                            fontSize: 13,
                            color: _cardAccent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cardAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text('开始',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
