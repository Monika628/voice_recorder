import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_recorder/audio_model.dart';
import 'package:voice_recorder/shared_preferences.dart';

class RecordingTaskHandler extends TaskHandler {
  static AudioRecorder? _recorder;
  static FlutterLocalNotificationsPlugin? _notifications;
  static String? _currentRecordingPath;
  static DateTime? _recordingStartTime;
  static Timer? _updateTimer;
  static bool _isRecording = false;
  static bool _isPaused = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Background recording task started');
    await _initializeRecording();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isRecording && !_isPaused) {
      _updateNotification();
    }
  }

  @override
  Future<void> onReceiveData(Object data) async {
    if (data is Map<String, dynamic>) {
      final action = data['action'] as String?;

      switch (action) {
        case 'start_recording':
          await _startRecording();
          break;
        case 'pause_recording':
          await _pauseRecording();
          break;
        case 'resume_recording':
          await _resumeRecording();
          break;
        case 'stop_recording':
          await _stopRecording();
          break;
        case 'update_notification':
          await _updateNotification();
          break;
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isSuccess) async {
    print('Background recording task destroyed (Success: $isSuccess)');
    await _stopRecording();
    await _cleanup();
  }

  static Future<void> _initializeRecording() async {
    try {
      _recorder = AudioRecorder();

      _notifications = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _notifications!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      print('Recording service initialized');
    } catch (e) {
      print('Error initializing recording service: $e');
    }
  }

  static Future<void> _startRecording() async {
    try {
      if (_recorder == null) return;

      if (!await _recorder!.hasPermission()) {
        print('Microphone permission denied');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _isPaused = false;
      _recordingStartTime = DateTime.now();

      _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateNotification();
      });

      await _showRecordingNotification();

      print('Recording started: $_currentRecordingPath');
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  static Future<void> _pauseRecording() async {
    try {
      if (_recorder == null || !_isRecording) return;

      await _recorder!.pause();
      _isPaused = true;

      await _updateNotification();
      print('Recording paused');
    } catch (e) {
      print('Error pausing recording: $e');
    }
  }

  static Future<void> _resumeRecording() async {
    try {
      if (_recorder == null || !_isRecording) return;

      await _recorder!.resume();
      _isPaused = false;

      await _updateNotification();
      print('Recording resumed');
    } catch (e) {
      print('Error resuming recording: $e');
    }
  }

  static Future<void> _stopRecording() async {
    try {
      if (_recorder == null) return;

      final path = await _recorder!.stop();
      _isRecording = false;
      _isPaused = false;

      _updateTimer?.cancel();
      _updateTimer = null;

      await _notifications?.cancel(1);

      if (path != null) {
        final fileName = path.split('/').last;

        final audioModel = AudioModel(
          path: path,
          recordedAt: _recordingStartTime ?? DateTime.now(),
          duration: _getRecordingDuration(),
          fileName: fileName,
        );

        await StorageHelper.addRecording(audioModel);

        FlutterForegroundTask.sendDataToMain({
          'action': 'recording_completed',
          'path': path,
          'duration': _getRecordingDuration(),
        });
      }

      print('Recording stopped');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  static Future<void> _showRecordingNotification() async {
    if (_notifications == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'recording_channel',
      'Audio Recording',
      channelDescription: 'Ongoing audio recording',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
      icon: '@mipmap/ic_launcher',
      color: Colors.red,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications!.show(
      1,
      'Recording Audio',
      _getNotificationText(),
      platformChannelSpecifics,
    );
  }

  static Future<void> _updateNotification() async {
    if (_notifications == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'recording_channel',
      'Audio Recording',
      channelDescription: 'Ongoing audio recording',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
      icon: '@mipmap/ic_launcher',
      color: Colors.red,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications!.show(
      1,
      'Recording Audio',
      _getNotificationText(),
      platformChannelSpecifics,
    );
  }

  static String _getNotificationText() {
    if (!_isRecording) return 'Recording stopped';
    if (_isPaused) return 'Recording paused • ${_getRecordingDuration()}';
    return 'Recording in progress • ${_getRecordingDuration()}';
  }

  static String _getRecordingDuration() {
    if (_recordingStartTime == null) return '00:00';

    final duration = DateTime.now().difference(_recordingStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static void _onNotificationTap(NotificationResponse response) {
    FlutterForegroundTask.sendDataToMain({
      'action': 'notification_tap',
    });
  }

  static Future<void> _cleanup() async {
    _updateTimer?.cancel();
    _updateTimer = null;

    if (_recorder != null) {
      await _recorder!.dispose();
      _recorder = null;
    }

    _notifications = null;
    _currentRecordingPath = null;
    _recordingStartTime = null;
    _isRecording = false;
    _isPaused = false;
  }
}

// Background Recording Manager
class BackgroundRecordingManager {
  static BackgroundRecordingManager? _instance;
  static BackgroundRecordingManager get instance {
    _instance ??= BackgroundRecordingManager._();
    return _instance!;
  }

  BackgroundRecordingManager._();

  bool _isInitialized = false;
  StreamController<Map<String, dynamic>>? _eventController;

  Stream<Map<String, dynamic>> get events => _eventController!.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _eventController = StreamController<Map<String, dynamic>>.broadcast();

    await _requestPermissions();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'recording_channel',
        channelName: 'Audio Recording',
        channelDescription: 'Ongoing audio recording',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.receivePort?.listen((data) {
      if (data is Map<String, dynamic>) {
        _eventController?.add(data);
      }
    });

    _isInitialized = true;
    print('Background recording manager initialized');
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.storage,
      Permission.notification,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        print('Permission denied: $permission');
      }
    }
  }

  Future<bool> startRecording() async {
    if (!_isInitialized) {
      await initialize();
    }

    final isActive = await FlutterForegroundTask.isRunningService;
    if (!isActive) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Audio Recording',
        notificationText: 'Preparing to record...',
        callback: startCallback,
      );
    }

    FlutterForegroundTask.sendDataToTask({
      'action': 'start_recording',
    });

    return true;
  }

  Future<void> pauseRecording() async {
    FlutterForegroundTask.sendDataToTask({
      'action': 'pause_recording',
    });
  }

  Future<void> resumeRecording() async {
    FlutterForegroundTask.sendDataToTask({
      'action': 'resume_recording',
    });
  }

  Future<void> stopRecording() async {
    FlutterForegroundTask.sendDataToTask({
      'action': 'stop_recording',
    });

    await Future.delayed(const Duration(seconds: 1));
    await FlutterForegroundTask.stopService();
  }

  void dispose() {
    _eventController?.close();
    _eventController = null;
    _isInitialized = false;
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}