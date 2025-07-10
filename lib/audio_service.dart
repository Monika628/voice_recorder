import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioService {
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;

  Future<void> init() async {
    _audioPlayer = AudioPlayer();
    _isInitialized = true;
  }

  Future<void> playFile(String path, VoidCallback onComplete) async {
    if (!_isInitialized || _audioPlayer == null) {
      throw Exception("Audio service not initialized");
    }

    await _audioPlayer!.play(DeviceFileSource(path));
    _audioPlayer!.onPlayerComplete.listen((event) {
      onComplete();
    });
  }

  Future<void> stopPlaying() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
  }

  void dispose() {
    _audioPlayer?.dispose();
  }
}
