import 'dart:ui';

import 'package:flutter/rendering.dart';

class Rope extends CustomPainter {
  final double segmentLength;
  final int numSegments;
  final double stiffness;
  final int iterations;
  final Offset gravity;
  final List<Color> colors;
  final Offset startPosition;
  final bool isDragging;
  final double thickness;
  final List<RopeSegment> _segments;

  Rope({
    required this.startPosition,
    required this.segmentLength,
    required this.numSegments,
    this.isDragging = false,
    this.stiffness = 0.2,
    this.iterations = 20,
    this.gravity = const Offset(0, 9.8),
    this.thickness = 5,
    this.colors = const [
      Color.fromRGBO(0, 0, 255, 1),
      Color.fromRGBO(255, 0, 0, 1)
    ],
  }) : _segments = List.generate(
          numSegments,
          (index) => RopeSegment(
            Offset(
              startPosition.dx,
              startPosition.dy + index * segmentLength,
            ),
          ),
        );

  List<RopeSegment> get segments => _segments;

  void drawRope(Canvas canvas, Path path, Paint paint, double strokeWidth) {
    const int braidSegments = 10;
    final PathMetrics pathMetrics = path.computeMetrics();
    final double totalLength = pathMetrics.fold<double>(
        0, (double prev, PathMetric pathMetric) => prev + pathMetric.length);

    for (double i = 0; i < totalLength; i += totalLength / braidSegments) {
      final PathMetric? pathMetric = pathMetrics.isNotEmpty
          ? pathMetrics.firstWhere((PathMetric pm) => pm.length >= i,
              orElse: () => pathMetrics.last)
          : null;
      if (pathMetric == null) continue;

      final double localTangentOffset =
          (i - pathMetric.length).clamp(0, pathMetric.length);
      final Tangent? tangent =
          pathMetric.getTangentForOffset(localTangentOffset);
      if (tangent == null) continue;

      final Offset normal =
          Offset(-tangent.vector.dy, tangent.vector.dx).normalize() *
              strokeWidth;

      final Offset start = tangent.position + normal;
      final Offset end = tangent.position - normal;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final path = Path();
    for (int i = 0; i < segments.length - 1; i++) {
      Offset a = segments[i].position;
      Offset b = segments[i + 1].position;

      final colorIndex = (i / segments.length * colors.length).floor();
      paint.color = colors[colorIndex % colors.length];

      path.moveTo(a.dx, a.dy);
      path.lineTo(b.dx, b.dy);
      canvas.drawPath(path, paint);
    }

    final pathMetrics = path.computeMetrics();
    final totalLength = pathMetrics.fold<double>(
        0, (double prev, PathMetric pathMetric) => prev + pathMetric.length);

    for (double i = 0; i < totalLength; i += totalLength / 10) {
      final PathMetric? pathMetric = pathMetrics.isNotEmpty
          ? pathMetrics.firstWhere((PathMetric pm) => pm.length >= i,
              orElse: () => pathMetrics.last)
          : null;
      if (pathMetric == null) continue;

      final double localTangentOffset =
          (i - pathMetric.length).clamp(0, pathMetric.length);
      final Tangent? tangent =
          pathMetric.getTangentForOffset(localTangentOffset);
      if (tangent == null) continue;

      final Offset normal =
          Offset(-tangent.vector.dy, tangent.vector.dx).normalize() * thickness;

      final Offset start = tangent.position + normal;
      final Offset end = tangent.position - normal;

      paint.color = colors[i.floor() % colors.length];
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void update({
    required double deltaTime,
    Offset? cursorPosition,
    double damping = 1.0,
    bool isDragging = false,
  }) {
    for (final segment in segments) {
      final velocity = (segment.position - segment.lastPosition) * damping;
      segment.lastPosition = segment.position;
      segment.position += velocity;
      segment.position += gravity * deltaTime;
    }

    // Set the last segment's position to the cursor position if dragging
    if (isDragging && cursorPosition != null) {
      segments.last.position = cursorPosition;
    }

    for (int iteration = 0; iteration < iterations; iteration++) {
      for (int i = 0; i < segments.length - 1; i++) {
        final a = segments[i];
        final b = segments[i + 1];
        final distance = (b.position - a.position).distance;
        final difference = segmentLength - distance;
        final direction = (b.position - a.position).normalize();
        final correction = direction * difference * stiffness;
        a.position -= correction * 0.5;
        b.position += correction * 0.5;
      }

      // Pin the first segment of the rope
      segments.first.position = startPosition;
    }
  }
}

class RopeSegment {
  Offset position;
  Offset lastPosition;
  RopeSegment(this.position) : lastPosition = position;
}

extension OffsetExtensions on Offset {
  Offset normalize() {
    double length = distance;
    return length != 0.0 ? this / length : this;
  }
}
