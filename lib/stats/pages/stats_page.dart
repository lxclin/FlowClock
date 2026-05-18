import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';
import '../providers/stats_provider.dart';
import '../widgets/distribution_chart.dart';
import '../widgets/pie_chart.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  String _timeRange = '日';
  List<Map<String, dynamic>> _pieData = [];
  int _lastFocusSeconds = -1;
  bool _loadingPie = false;

  Future<void> _loadPieData() async {
    if (_loadingPie) return;
    _loadingPie = true;
    final now = DateTime.now();
    DateTime start;
    switch (_timeRange) {
      case '周':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case '月':
        start = DateTime(now.year, now.month, 1);
        break;
      case '年':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }
    final data = await DatabaseHelper.instance.getTaskFocusByRange(start, now);
    if (mounted) setState(() { _pieData = data; _loadingPie = false; });
  }

  @override
  void initState() {
    super.initState();
    _loadPieData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPieData();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    if (stats.isLoading) return const Center(child: CircularProgressIndicator());

    // Detect stats change and reload pie data
    if (stats.totalFocusSeconds != _lastFocusSeconds) {
      _lastFocusSeconds = stats.totalFocusSeconds;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPieData());
    }

    final focusMinutes = stats.todayFocusSeconds ~/ 60;
    final totalMinutes = stats.totalFocusSeconds ~/ 60;
    final displayToday = focusMinutes >= 60 ? '${(stats.todayFocusSeconds / 3600).toStringAsFixed(1)} 小时' : '$focusMinutes 分钟';
    final displayTotal = totalMinutes >= 60 ? '${(stats.totalFocusSeconds / 3600).toStringAsFixed(1)} 小时' : '$totalMinutes 分钟';

    return Container(
      color: AppTheme.bgCream,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            const Text('统计', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),

            // ── Today Overview ──
            _LoFiCard(child: Column(children: [
              const Text('今日专注', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(displayToday, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w200, color: AppTheme.workColor)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _StatChip(label: '完成', value: '${stats.todayCompleted}', color: AppTheme.accentCool),
                _StatChip(label: '中断', value: '${stats.todayInterrupted}', color: AppTheme.accentWarm),
                _StatChip(label: '放弃', value: '${stats.todayAbandoned}', color: AppTheme.textSecondary),
              ]),
            ])),
            const SizedBox(height: 14),

            // ── Pie Chart with time range ──
            _LoFiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('专注时长分布',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                DropdownButton<String>(
                  value: _timeRange,
                  underline: const SizedBox(),
                  items: ['日', '周', '月', '年']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _timeRange = v!);
                    _loadPieData();
                  },
                ),
              ]),
              const SizedBox(height: 16),
              Center(child: PieChart(data: _pieData)),
            ])),
            const SizedBox(height: 14),

            // ── Hourly Distribution ──
            _LoFiCard(child: DistributionChart(hourlyData: stats.hourlyDistribution)),
            const SizedBox(height: 14),

            // ── Weekly Stats ──
            _LoFiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('本周统计',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('总专注 $displayTotal · ${stats.totalSessions} 个番茄',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 14),
              if (stats.weeklyStats.isEmpty)
                const Text('暂无数据', style: TextStyle(color: AppTheme.textSecondary))
              else
                _WeekRow(weeklyStats: stats.weeklyStats),
            ])),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _LoFiCard extends StatelessWidget {
  final Widget child;
  const _LoFiCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor, width: 1)),
        child: child,
      );
}

class _StatChip extends StatelessWidget {
  final String label; final String value; final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]);
}

class _WeekRow extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyStats;
  const _WeekRow({required this.weeklyStats});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final labels = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final match = weeklyStats.where((s) => s['date'] == dateKey).toList();
      final seconds = match.isEmpty ? 0 : match.first['total_focus_seconds'] as int;
      final minutes = (seconds / 60).round();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      return Column(children: [
        Text(labels[i], style: TextStyle(fontSize: 12, color: isToday ? AppTheme.workColor : AppTheme.textSecondary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
        const SizedBox(height: 8),
        Container(width: 38, height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: minutes > 0 ? (isToday ? AppTheme.workColor : AppTheme.accentCool.withValues(alpha: 0.7)) : AppTheme.trackColor),
            child: Center(child: Text(minutes > 0 ? '${minutes}m' : '',
                style: TextStyle(fontSize: 10, color: minutes > 0 ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w700)))),
      ]);
    }));
  }
}
