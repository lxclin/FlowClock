import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyData;

  const DistributionChart({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    final maxSeconds = hourlyData.isEmpty
        ? 1
        : hourlyData
            .map((h) => h['focus_seconds'] as int)
            .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('今日专注分布',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: hourlyData.isEmpty
              ? const Center(child: Text('暂无数据', style: TextStyle(color: AppTheme.textSecondary)))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: hourlyData.map((h) {
                    final hour = h['hour'] as int;
                    final seconds = h['focus_seconds'] as int;
                    final heightFactor = maxSeconds > 0 ? seconds / maxSeconds : 0.0;
                    final minutes = (seconds / 60).round();

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (minutes > 0)
                              Text('${minutes}m',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: heightFactor.clamp(0.02, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.workColor.withValues(alpha: 0.7),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$hour',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
