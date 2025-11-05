import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// _DashedBorderPainter
/// ═══════════════════════════════════════════════════════════════════════════
///
/// CustomPainter для отрисовки пунктирной границы.
///
/// **Параметры:**
/// - color: цвет линии
/// - strokeWidth: толщина линии
/// - dashWidth: длина штриха
/// - dashSpace: расстояние между штрихами
/// - borderRadius: радиус скругления углов
///
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    // Создаем пунктирный эффект
    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  /// [_createDashedPath] Создает пунктирный путь из обычного пути
  Path _createDashedPath(Path source) {
    final dashedPath = Path();
    final metricsIterator = source.computeMetrics().iterator;

    while (metricsIterator.moveNext()) {
      final metric = metricsIterator.current;
      double distance = 0;

      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        dashedPath.addPath(extractPath, Offset.zero);
        distance = nextDistance + dashSpace;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

