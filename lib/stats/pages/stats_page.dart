import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final weekDates = ref.read(statsProvider.notifier).getWeekDates();
    final totalHours = (stats.totalMinutes / 60).toStringAsFixed(1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.workBackground, Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                '今日',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.todayCount}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: AppTheme.workColor,
                  height: 1,
                ),
              ),
              const Text(
                '个番茄',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _StatsCard(
                icon: Icons.timer_rounded,
                label: '总专注时长',
                value: '$totalHours 小时',
                color: AppTheme.workColor,
              ),
              const SizedBox(height: 12),
              _StatsCard(
                icon: Icons.calendar_today_rounded,
                label: '本周',
                value: '${_weekTotal(ref)} 个番茄',
                color: AppTheme.breakColor,
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '本周',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _WeekCalendar(weekDates: weekDates, ref: ref),
            ],
          ),
        ),
      ),
    );
  }

  int _weekTotal(WidgetRef ref) {
    final stats = ref.read(statsProvider.notifier);
    final weekDates = stats.getWeekDates();
    return weekDates.fold(0, (sum, date) => sum + stats.getCountForDate(date));
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  final List<DateTime> weekDates;
  final WidgetRef ref;

  const _WeekCalendar({required this.weekDates, required this.ref});

  @override
  Widget build(BuildContext context) {
    final statsNotifier = ref.read(statsProvider.notifier);
    final today = DateTime.now();
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final date = weekDates[i];
        final count = statsNotifier.getCountForDate(date);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        return Column(
          children: [
            Text(
              dayNames[i],
              style: TextStyle(
                fontSize: 12,
                color: isToday ? AppTheme.workColor : AppTheme.textSecondary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count > 0
                    ? (isToday ? AppTheme.workColor : AppTheme.breakColor)
                    : AppTheme.trackColor,
              ),
              child: Center(
                child: Text(
                  count > 0 ? '$count' : '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: count > 0 ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? AppTheme.workColor : AppTheme.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}
