
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voice_recorder/audio_model.dart';
import 'package:voice_recorder/audio_service.dart';
import 'package:voice_recorder/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AudioModel> recordings = [];
  final AudioService _audioService = AudioService();
  String? currentlyPlaying;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAudioAndLoad();
  }

  Future<void> _initializeAudioAndLoad() async {
    await _audioService.init();
    await _loadRecordings();
  }

  Future<void> _play(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Audio file not found!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentlyPlaying == path) {
      await _audioService.stopPlaying();
      setState(() => currentlyPlaying = null);
      return;
    }

    setState(() => currentlyPlaying = path);

    await _audioService.playFile(path, () {
      if (mounted) {
        setState(() => currentlyPlaying = null);
      }
    });
  }

  Future<void> _loadRecordings() async {
    setState(() => isLoading = true);

    try {
      final items = await StorageHelper.getRecordings();
      final validItems = <AudioModel>[];

      for (var rec in items) {
        if (await File(rec.path).exists()) {
          validItems.add(rec);
        }
      }

      if (mounted) {
        setState(() {
          recordings = validItems.reversed.toList();
          isLoading = false;
        });
      }

      print("Loaded ${recordings.length} recordings");
    } catch (e) {
      print("Error loading recordings: $e");
      if (mounted) {
        setState(() {
          recordings = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRecording(int displayIndex) async {
    if (displayIndex < 0 || displayIndex >= recordings.length) return;

    final recordingToDelete = recordings[displayIndex];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text('Delete Recording', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete Recording ${displayIndex + 1}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Stop playing if this file is currently playing
        if (currentlyPlaying == recordingToDelete.path) {
          await _audioService.stopPlaying();
          setState(() => currentlyPlaying = null);
        }

        // Get all recordings from storage
        final allRecordings = await StorageHelper.getRecordings();

        // Find the actual index in the original list
        int actualIndex = -1;
        for (int i = 0; i < allRecordings.length; i++) {
          if (allRecordings[i].path == recordingToDelete.path &&
              allRecordings[i].recordedAt == recordingToDelete.recordedAt) {
            actualIndex = i;
            break;
          }
        }

        if (actualIndex != -1) {
          // Delete from storage
          await StorageHelper.deleteRecording(actualIndex);

          // Immediately update UI by removing from local list
          setState(() {
            recordings.removeAt(displayIndex);
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Recording deleted successfully"),
                backgroundColor: Colors.black,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Reload from storage to ensure consistency
          await _loadRecordings();
        } else {
          throw Exception("Recording not found in storage");
        }
      } catch (e) {
        print("Error deleting recording: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting recording: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Reload recordings to refresh the UI in case of error
        await _loadRecordings();
      }
    }
  }

  Future<void> _refreshRecordings() async {
    await _loadRecordings();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const   Color(0xFF1E1550),
      appBar: AppBar(
        title: const Text("Recording History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        backgroundColor: const  Color(0xFF1E1550),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecordings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : recordings.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("No recordings found", style: TextStyle(color: Colors.grey, fontSize: 18)),
            SizedBox(height: 8),
            Text("Start recording to see your files here", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshRecordings,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordings.length,
          itemBuilder: (context, index) {
            final rec = recordings[index];
            final file = File(rec.path);
            final fileSize = file.existsSync() ? file.lengthSync() : 0;
            final isPlaying = currentlyPlaying == rec.path;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPlaying ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPlaying ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mic, color: isPlaying ? Colors.red : Colors.grey, size: 24),
                ),
                title: Text(
                  "Recording ${index + 1}",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(_formatDateTime(rec.recordedAt), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(_formatFileSize(fileSize), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        if (rec.duration.isNotEmpty)
                          Text("• ${rec.duration}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          color: isPlaying ? Colors.red : Colors.white,
                        ),
                        onPressed: () => _play(rec.path),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.green),
                        onPressed: () => Share.shareXFiles([XFile(rec.path)], text: 'Check out my voice recording!'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecording(index),
                      ),
                    ),
                  ],
                ),

              ),
            );
          },
        ),
      ),
    );
  }
}