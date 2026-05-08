import 'dart:math';
import 'package:flutter/material.dart';

class CircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;
  final Widget? centerChild;
  final String? label;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 260,
    this.strokeWidth = 12,
    this.progressColor = Colors.red,
    this.trackColor = const Color(0xFFE9ECEF),
    this.centerChild,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: progress.clamp(0.0, 1.0),
              progressColor: progressColor,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          if (centerChild != null) centerChild!,
          if (label != null)
            Positioned(
              bottom: size * 0.18,
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 14,
                  color: progressColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          progressColor.withValues(alpha: 0.6),
          progressColor,
        ],
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
      ).createShader(rect);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);

    final shadowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
