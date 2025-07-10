import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:voice_recorder/audio_model.dart';
import 'package:voice_recorder/gradient_visualizer.dart';
import 'package:voice_recorder/settings_screen.dart';
import 'package:voice_recorder/shared_preferences.dart';
import 'history_screen.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({Key? key}) : super(key: key);

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  bool isRecording = false;
  late Timer _timer;
  Duration elapsed = Duration.zero;
  List<String> fileList = [];
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/recordings');

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final fileName = "audio_${DateTime.now().millisecondsSinceEpoch}.wav";
    return '${recordingsDir.path}/$fileName';
  }

  void _startRecording() async {
    // Request microphone permission
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission is required!")),
      );
      return;
    }

    try {
      // Get the recording path
      _currentRecordingPath = await _getRecordingPath();

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      setState(() {
        isRecording = true;
        elapsed = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          elapsed += const Duration(seconds: 1);
        });
      });

      print("Recording started: $_currentRecordingPath");
    } catch (e) {
      print("Error starting recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting recording: $e")),
      );
    }
  }

  void _stopRecording({bool save = true}) async {
    if (_timer.isActive) _timer.cancel();

    final recordedDuration = elapsed;

    try {
      // Stop recording
      await _recorder.stop();

      setState(() {
        isRecording = false;
        elapsed = Duration.zero;
      });

      if (save && _currentRecordingPath != null) {
        // Check if file exists
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final fileName = _currentRecordingPath!.split('/').last;

          final model = AudioModel(
            fileName: fileName,
            path: _currentRecordingPath!,
            recordedAt: DateTime.now(),
            duration: _formatDuration(recordedDuration).substring(3),
          );

          await StorageHelper.addRecording(model);

          print("Recording saved: ${model.fileName} at ${model.path}");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recording saved!"), backgroundColor: Colors.black),
          );
        } else {
          print("Recording file not found: $_currentRecordingPath");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recording file not found!")),
          );
        }
      } else {
        // Delete the file if not saving
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording discarded!"), backgroundColor: Colors.black),
        );
      }
    } catch (e) {
      print("Error stopping recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error stopping recording: $e")),
      );
    }

    _currentRecordingPath = null;
  }

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, "0");
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coming soon!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Voice Recorder', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: const Color(0xFF0B0620),
      ),
      backgroundColor: const Color(0xFF0B0620),
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1550),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navIcon(Icons.settings, () => _onBottomNavTap(0)),
                const SizedBox(width: 60),
                _navIcon(Icons.folder, () => _onBottomNavTap(1)),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: IconButton(
                icon: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white
                ),
                iconSize: 36,
                onPressed: isRecording ? () => _stopRecording(save: true) : _startRecording,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // GradientVisualizer hamesha visible hai, lekin sirf recording time animate hota hai
          GradientVisualizer(isActive: isRecording),
          const SizedBox(height: 30),
          // Timer text hamesha visible hai
          Text(
            isRecording ? _formatDuration(elapsed).substring(3) : '00:00',
            style: const TextStyle(fontSize: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Recording status text hamesha visible hai
          Text(
            isRecording ? "Recording..." : "Ready to Record",
            style: TextStyle(
              color: isRecording ? Colors.red : Colors.grey,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          // Save/Discard buttons hamesha visible hain
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRoundButton(
                    Icons.close,
                    "Discard",
                    isRecording ? () => _stopRecording(save: false) : null
                ),
                _buildRoundButton(
                    Icons.check,
                    "Save",
                    isRecording ? () => _stopRecording(save: true) : null
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0B0620),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, String label, VoidCallback? onTap) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap != null ? const Color(0xFF1E1550) : const Color(0xFF1E1550).withOpacity(0.5),
          ),
          child: IconButton(
            icon: Icon(
                icon,
                color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5)
            ),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(
            label,
            style: TextStyle(
                color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5)
            )
        ),
      ],
    );
  }
}