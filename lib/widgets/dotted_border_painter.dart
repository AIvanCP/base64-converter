import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math';

/// Custom painter to draw a dotted border on a container
class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    this.color = const Color(0xFF9E9E9E),
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ),
    );

    // Calculate the length of the path
    final PathMetrics metrics = path.computeMetrics();
    final PathMetric metric = metrics.first;
    final double dashLength = 5;
    double distance = 0.0;

    // Draw the dashed path
    while (distance < metric.length) {
      final double next = distance + dashLength;
      if (next > metric.length) {
        break;
      }
      final Path extractPath = metric.extractPath(distance, next);
      canvas.drawPath(extractPath, paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
