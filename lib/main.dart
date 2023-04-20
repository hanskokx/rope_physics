import 'dart:async';

import 'package:flutter/material.dart';
import 'package:physics_demo/rope.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: RopeSimulation())));
}

class RopeSimulation extends StatefulWidget {
  const RopeSimulation({super.key});

  @override
  State<RopeSimulation> createState() => _RopeSimulationState();
}

class _RopeSimulationState extends State<RopeSimulation> {
  late final Rope rope;
  final double segmentLength = 20.0;
  final double stiffness =
      0.2; // Decrease the value to make the rope more wiggly
  final int iterations = 20;
  final Offset gravity = const Offset(
    0,
    9.8,
  ); // Increase the vertical component for a stronger gravity effect. 9.8 is Earth gravity.

  Timer? _timer;
  Offset? _cursorPosition;
  bool _isDragging = false;
  DateTime _lastFrameTime = DateTime.now();
  late double deltaTime;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    deltaTime = (now.difference(_lastFrameTime)).inMicroseconds / 1000000.0;
    _lastFrameTime = now;
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _cursorPosition = details.localPosition;
          });
        },
        onPanStart: (details) {
          setState(() {
            _cursorPosition = details.localPosition;
            _isDragging = true;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _cursorPosition = null;
            _isDragging = false;
          });
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: rope,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    rope = Rope(
      startPosition: const Offset(100, 100),
      numSegments: 20,
      segmentLength: 20,
      stiffness: 0.2,
      iterations: 20,
      gravity: const Offset(0, 9.8),
      colors: [
        const Color.fromRGBO(0, 0, 255, 1),
        const Color.fromRGBO(255, 0, 0, 1)
      ],
    );

    _lastFrameTime = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final now = DateTime.now();
      deltaTime = (now.difference(_lastFrameTime)).inMicroseconds / 1000000.0;
      _lastFrameTime = now;

      rope.update(
        deltaTime: deltaTime,
        cursorPosition: _cursorPosition,
        isDragging: _isDragging,
        damping: _isDragging ? 1.0 : 0.98,
      );

      if (_isDragging && _cursorPosition != null) {
        rope.segments.last.position = _cursorPosition!;
        rope.segments.last.lastPosition = _cursorPosition!;
      }

      setState(() {});
    });
  }
}
