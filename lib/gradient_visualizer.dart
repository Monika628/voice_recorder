import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

class GradientVisualizer extends StatefulWidget {
  final bool isActive;

  const GradientVisualizer({Key? key, this.isActive = false}) : super(key: key);

  @override
  State<GradientVisualizer> createState() => _GradientVisualizerState();
}

class _GradientVisualizerState extends State<GradientVisualizer> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _animationTimer;
  List<double> bars = List.generate(100, (index) => 0.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      startAnimation();
    }
  }

  @override
  void didUpdateWidget(GradientVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        startAnimation();
      } else {
        stopAnimation();
      }
    }
  }

  void startAnimation() {
    // Animated bars without actually recording
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          bars = List.generate(
            100,
                (index) => _random.nextDouble() * 100 + 20, // Random heights
          );
        });
      }
    });
  }

  void stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    if (mounted) {
      setState(() {
        bars = List.generate(100, (index) => 0.0);
      });
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: screenWidth,
      height: screenHeight * 0.25,
      child: CustomPaint(
        painter: _VisualizerPainter(bars),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final List<double> bars;
  _VisualizerPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / bars.length;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E1550), Colors.blue],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < bars.length; i++) {
      final x = i * barWidth;
      final barHeight = bars[i].clamp(2.0, size.height);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - barHeight, barWidth * 0.8, barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}