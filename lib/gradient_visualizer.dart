import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart' as ms;

class GradientVisualizer extends StatefulWidget {
  final dynamic isActive;

  const GradientVisualizer({Key? key, this.isActive = false}) : super(key: key);

  @override
  State<GradientVisualizer> createState() => _GradientVisualizerState();
}

class _GradientVisualizerState extends State<GradientVisualizer> {
  Stream<List<int>>? _micStream;
  StreamSubscription<List<int>>? _micSubscription;
  List<double> bars = List.generate(100, (index) => 0.0);

  @override
  void initState() {
    super.initState();
    startMicStream();
  }

  void startMicStream() async {
    _micStream = await ms.MicStream.microphone(
      audioSource: ms.AudioSource.DEFAULT,
      sampleRate: 44100,
      channelConfig: ms.ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: ms.AudioFormat.ENCODING_PCM_16BIT,
    );

    _micSubscription = _micStream?.listen((data) {
      double avgAmplitude = calculateAverageAmplitude(data);
      if (mounted) {
        setState(() {
          bars = List.generate(100, (index) => avgAmplitude * Random().nextDouble() * 3);
        });
      }
    });
  }

  double calculateAverageAmplitude(List<int> data) {
    if (data.isEmpty) return 0;
    double sum = 0;
    for (var value in data) {
      sum += value.abs();
    }
    return sum / data.length;
  }

  @override
  void dispose() {
    _micSubscription?.cancel();
    _micSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VisualizerPainter(bars),
      child: Container(height: 200), // height of the visualizer
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
      final barHeight = bars[i];
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - barHeight, barWidth * 0.8, barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
