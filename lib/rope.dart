import 'dart:math';
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
  final bool _coiled;

  factory Rope({
    required Offset startPosition,
    required double segmentLength,
    required int numSegments,
    bool isDragging = false,
    double stiffness = 0.2,
    int iterations = 20,
    Offset gravity = const Offset(0, 9.8),
    int thickness = 5,
    List<Color> colors = const [
      Color.fromRGBO(0, 0, 255, 1),
      Color.fromRGBO(255, 0, 0, 1)
    ],
  }) {
    final segments = List.generate(
      numSegments,
      (index) => RopeSegment(
        Offset(
          startPosition.dx,
          startPosition.dy + index * segmentLength,
        ),
      ),
    );
    return Rope._(
      segments,
      startPosition: startPosition,
      numSegments: numSegments,
      segmentLength: segmentLength,
      stiffness: stiffness,
      iterations: iterations,
      gravity: gravity,
      colors: colors,
      thickness: thickness.toDouble(),
      isDragging: isDragging,
      coiled: false,
    );
  }

  factory Rope.coiled({
    required Offset startPosition,
    required double segmentLength,
    required int numSegments,
    bool isDragging = false,
    double stiffness = 0.2,
    int iterations = 20,
    Offset gravity = const Offset(0, 9.8),
    int thickness = 5,
    List<Color> colors = const [
      Color.fromRGBO(0, 0, 255, 1),
      Color.fromRGBO(255, 0, 0, 1)
    ],
  }) {
    final segments = List.generate(
      numSegments,
      (index) => RopeSegment(
        Offset(
          startPosition.dx,
          startPosition.dy + index * segmentLength,
        ),
      ),
    );
    return Rope._(
      segments,
      startPosition: startPosition,
      numSegments: numSegments,
      segmentLength: segmentLength,
      stiffness: stiffness,
      iterations: iterations,
      gravity: gravity,
      colors: colors,
      thickness: thickness.toDouble(),
      isDragging: isDragging,
      coiled: true,
    );
  }

  Rope._(
    this._segments, {
    required this.startPosition,
    required this.segmentLength,
    required this.numSegments,
    this.isDragging = false,
    this.stiffness = 0.2,
    this.iterations = 20,
    this.gravity = const Offset(0, 9.8),
    this.thickness = 5,
    required bool coiled,
    required this.colors,
  }) : _coiled = coiled;

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
    if (_coiled) {
      paintCoiled(canvas, size);
    } else {
      paintStraight(canvas, size);
    }
  }

  void paintCoiled(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = colors[0]
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = colors[1]
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final double wrapInterval = segmentLength / 2;

    Path path1 = Path();
    Path path2 = Path();

    for (int i = 0; i < segments.length - 1; i++) {
      final segmentA = segments[i];
      final segmentB = segments[i + 1];
      final angle = atan2(
        segmentB.position.dy - segmentA.position.dy,
        segmentB.position.dx - segmentA.position.dx,
      );

      final double dx = segmentB.position.dx - segmentA.position.dx;
      final double dy = segmentB.position.dy - segmentA.position.dy;

      final double offsetX1 = cos(angle + pi / 2) * 2;
      final double offsetY1 = sin(angle + pi / 2) * 2;
      final double offsetX2 = cos(angle - pi / 2) * 2;
      final double offsetY2 = sin(angle - pi / 2) * 2;

      for (double t = 0; t <= 1; t += 0.01) {
        final double x = segmentA.position.dx + dx * t;
        final double y = segmentA.position.dy + dy * t;

        final double offsetX = cos(t * pi * 2 * wrapInterval) * 3;
        final double offsetY = sin(t * pi * 2 * wrapInterval) * 3;

        final double x1 = x + offsetX * offsetX1;
        final double y1 = y + offsetY * offsetY1;
        final double x2 = x + offsetX * offsetX2;
        final double y2 = y + offsetY * offsetY2;

        if (t == 0 && i == 0) {
          path1.moveTo(x1, y1);
          path2.moveTo(x2, y2);
        } else {
          path1.lineTo(x1, y1);
          path2.lineTo(x2, y2);
        }
      }
    }

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  void paintStraight(Canvas canvas, Size size) {
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

  Path wrapPath(Path originalPath, double wrapInterval) {
    final Path wrappedPath = Path();
    final PathMetric pathMetric = originalPath.computeMetrics().first;
    final double totalLength = pathMetric.length;

    for (double t = 0; t < totalLength; t += totalLength / wrapInterval) {
      final tangent1 = pathMetric.getTangentForOffset(t);
      final tangent2 =
          pathMetric.getTangentForOffset(t + totalLength / (2 * wrapInterval));
      final tangent3 =
          pathMetric.getTangentForOffset(t + totalLength / wrapInterval);

      wrappedPath.moveTo(tangent1!.position.dx, tangent1.position.dy);
      wrappedPath.quadraticBezierTo(tangent2!.position.dx, tangent2.position.dy,
          tangent3!.position.dx, tangent3.position.dy);
    }

    return wrappedPath;
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
