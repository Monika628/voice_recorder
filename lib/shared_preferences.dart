import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_recorder/audio_model.dart';

class StorageHelper {
  static const String _key = 'audio_recordings';


  static Future<void> addRecording(AudioModel model) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];
    recordings.add(jsonEncode(model.toJson()));

    await prefs.setStringList(_key, recordings);
  }

  static Future<List<AudioModel>> getRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    return recordings
        .map((item) => AudioModel.fromJson(jsonDecode(item)))
        .toList();
  }
  static Future<void> deleteRecording(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    if (index >= 0 && index < recordings.length) {

      try {
        final audioModel = AudioModel.fromJson(jsonDecode(recordings[index]));

        final file = File(audioModel.path);
        if (await file.exists()) {
          await file.delete();
          print("Physical file deleted: ${audioModel.path}");
        }
      } catch (e) {
        print("Error deleting physical file: $e");
      }

      recordings.removeAt(index);
      await prefs.setStringList(_key, recordings);
      print("Recording deleted from index: $index");
    }
  }

  static Future<void> deleteRecordingByModel(AudioModel model) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recordings = prefs.getStringList(_key) ?? [];

    recordings.removeWhere((item) {
      try {
        final audioModel = AudioModel.fromJson(jsonDecode(item));
        return audioModel.fileName == model.fileName && audioModel.path == model.path;
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList(_key, recordings);

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


  static Future<void> clearRecordings() async {
    final prefs = await SharedPreferences.getInstance();

    final recordings = await getRecordings();


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

    await prefs.remove(_key);
  }

  static Future<int> getRecordingCount() async {
    final recordings = await getRecordings();
    return recordings.length;
  }

  static Future<bool> recordingExists(String fileName) async {
    final recordings = await getRecordings();
    return recordings.any((recording) => recording.fileName == fileName);
  }
}