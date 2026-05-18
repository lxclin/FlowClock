import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double size;

  PieChart({super.key, required this.data, this.size = 180});

  List<PieSlice> _buildSlices() {
    if (data.isEmpty) return [];
    final total = data.fold<int>(0, (sum, d) => sum + (d['total_seconds'] as int));
    if (total == 0) return [];
    return data.map((d) {
      final seconds = d['total_seconds'] as int;
      final pct = seconds / total;
      final colorIndex = d['color_index'] as int? ?? 0;
      return PieSlice(
        title: d['title'] as String? ?? '未分类',
        seconds: seconds,
        percent: pct,
        color: AppTheme.taskAccentColors[colorIndex % 8],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final slices = _buildSlices();
    final totalSeconds = slices.isEmpty ? 0 : slices.fold<int>(0, (s, sl) => s + sl.seconds);
    final totalDisplay = totalSeconds >= 3600
        ? '${(totalSeconds / 3600).toStringAsFixed(1)} 小时'
        : '${totalSeconds ~/ 60} 分钟';

    return Column(
      children: [
        if (slices.isEmpty)
          const Text('暂无数据', style: TextStyle(color: AppTheme.textSecondary))
        else ...[
          SizedBox(
            width: size, height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size(size, size), painter: PieChartPainter(slices: slices)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('总计', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text(totalDisplay, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...slices.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(child: Text(s.title, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
              Text(s.seconds >= 3600 ? '${(s.seconds / 3600).toStringAsFixed(1)}h' : '${s.seconds ~/ 60}m',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Text('${(s.percent * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          )),
        ],
      ],
    );
  }
}

class PieSlice {
  final String title; final int seconds; final double percent; final Color color;
  const PieSlice({required this.title, required this.seconds, required this.percent, required this.color});
}

class PieChartPainter extends CustomPainter {
  final List<PieSlice> slices;
  PieChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    double startAngle = -pi / 2;
    for (final slice in slices) {
      final sweepAngle = 2 * pi * slice.percent;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true,
          Paint()..color = slice.color..style = PaintingStyle.fill);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) => slices != oldDelegate.slices;
}
