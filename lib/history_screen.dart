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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
            'Delete Recording',
            style: TextStyle(color: Theme.of(context).textTheme.headlineSmall?.color)
        ),
        content: Text(
          'Are you sure you want to delete Recording ${displayIndex + 1}?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)
            ),
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
        if (currentlyPlaying == recordingToDelete.path) {
          await _audioService.stopPlaying();
          setState(() => currentlyPlaying = null);
        }

        final allRecordings = await StorageHelper.getRecordings();

        int actualIndex = -1;
        for (int i = 0; i < allRecordings.length; i++) {
          if (allRecordings[i].path == recordingToDelete.path &&
              allRecordings[i].recordedAt == recordingToDelete.recordedAt) {
            actualIndex = i;
            break;
          }
        }

        if (actualIndex != -1) {
          await StorageHelper.deleteRecording(actualIndex);
          setState(() {
            recordings.removeAt(displayIndex);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Recording deleted successfully"),
                backgroundColor: Colors.black,
                duration: Duration(seconds: 2),
              ),
            );
          }
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Recording History",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _refreshRecordings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      )
          : recordings.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: size.height * 0.1,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              "No recordings found",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: size.width * 0.045,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              "Start recording to see your files here",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: size.width * 0.035,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshRecordings,
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).cardColor,
        child: ListView.builder(
          padding: EdgeInsets.all(size.width * 0.04),
          itemCount: recordings.length,
          itemBuilder: (context, index) {
            final rec = recordings[index];
            final file = File(rec.path);
            final fileSize = file.existsSync() ? file.lengthSync() : 0;
            final isPlaying = currentlyPlaying == rec.path;

            return Container(
              margin: EdgeInsets.only(bottom: size.height * 0.015),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPlaying
                      ? Colors.red.withOpacity(0.3)
                      : Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(size.width * 0.04),
                leading: Container(
                  width: size.width * 0.12,
                  height: size.width * 0.12,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Colors.red.withOpacity(0.1)
                        : Theme.of(context).cardColor?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mic,
                    color: isPlaying ? Colors.red : Theme.of(context).iconTheme.color,
                    size: size.width * 0.06,
                  ),
                ),
                title: Text(
                  "Recording ${index + 1}",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.005),
                    Text(
                      _formatDateTime(rec.recordedAt),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: size.width * 0.035,
                      ),
                    ),
                    SizedBox(height: size.height * 0.003),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatFileSize(fileSize),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: size.width * 0.03,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        if (rec.duration.isNotEmpty)
                          Expanded(
                            child: Text(
                              "• ${rec.duration}",
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: size.width * 0.03,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    )

                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          color: isPlaying ? Colors.red : Theme.of(context).iconTheme.color,
                          size: size.width * 0.06,
                        ),
                        onPressed: () => _play(rec.path),
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.share, color: Colors.green, size: size.width * 0.06),
                        onPressed: () => Share.shareXFiles(
                          [XFile(rec.path)],
                          text: 'Check out my voice recording!',
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: size.width * 0.06),
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