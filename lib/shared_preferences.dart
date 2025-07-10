import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_recorder/audio_model.dart';

class StorageHelper {
  static const String _key = 'audio_recordings';

  static Future<void> addRecording(AudioModel model) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    // Convert AudioModel to JSON string
    recordings.add(jsonEncode(model.toJson()));

    await prefs.setStringList(_key, recordings);
  }

  /// Get all saved AudioModel recordings
  static Future<List<AudioModel>> getRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    return recordings
        .map((item) => AudioModel.fromJson(jsonDecode(item)))
        .toList();
  }

  /// Delete a recording by index and also delete the physical file
  static Future<void> deleteRecording(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    if (index >= 0 && index < recordings.length) {
      // Get the audio model to delete the physical file
      try {
        final audioModel = AudioModel.fromJson(jsonDecode(recordings[index]));

        // Delete the physical file if it exists
        final file = File(audioModel.path);
        if (await file.exists()) {
          await file.delete();
          print("Physical file deleted: ${audioModel.path}");
        }
      } catch (e) {
        print("Error deleting physical file: $e");
      }

      // Remove from shared preferences
      recordings.removeAt(index);
      await prefs.setStringList(_key, recordings);
      print("Recording deleted from index: $index");
    }
  }

  /// Delete a recording by AudioModel (alternative method)
  static Future<void> deleteRecordingByModel(AudioModel model) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    // Find and remove the matching recording
    recordings.removeWhere((item) {
      try {
        final audioModel = AudioModel.fromJson(jsonDecode(item));
        return audioModel.fileName == model.fileName && audioModel.path == model.path;
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList(_key, recordings);

    // Delete the physical file
    try {
      final file = File(model.path);
      if (await file.exists()) {
        await file.delete();
        print("Physical file deleted: ${model.path}");
      }
    } catch (e) {
      print("Error deleting physical file: $e");
    }
  }

  /// Clear all recordings and delete all physical files
  static Future<void> clearRecordings() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all recordings to delete physical files
    final recordings = await getRecordings();

    // Delete all physical files
    for (final recording in recordings) {
      try {
        final file = File(recording.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print("Error deleting file ${recording.path}: $e");
      }
    }

    // Clear from shared preferences
    await prefs.remove(_key);
  }

  /// Get total number of recordings
  static Future<int> getRecordingCount() async {
    final recordings = await getRecordings();
    return recordings.length;
  }

  /// Check if a recording exists by filename
  static Future<bool> recordingExists(String fileName) async {
    final recordings = await getRecordings();
    return recordings.any((recording) => recording.fileName == fileName);
  }
}