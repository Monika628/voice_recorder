
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_recorder/audio_model.dart';
import 'package:voice_recorder/forgot_password_screen.dart';
import 'package:voice_recorder/gradient_visualizer.dart';
import 'package:voice_recorder/login_screen.dart';
import 'package:voice_recorder/settings_screen.dart';
import 'package:voice_recorder/shared_preferences.dart';
import 'history_screen.dart';

class RecorderScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const RecorderScreen({Key? key, this.onThemeChanged}) : super(key: key);

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
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  InterstitialAd? _interstitialAd;
  int _recordingSaveCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    _recorder.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
          print('Banner Ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial Ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial Ad failed to show: $error');
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
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
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission is required!")),
      );
      return;
    }

    try {
      _currentRecordingPath = await _getRecordingPath();
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
      await _recorder.stop();

      setState(() {
        isRecording = false;
        elapsed = Duration.zero;
      });

      if (save && _currentRecordingPath != null) {
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
            const SnackBar(content: Text("Recording saved!"), backgroundColor: Colors.green),
          );

          _recordingSaveCount++;
          if (_recordingSaveCount % 3 == 0) {
            _showInterstitialAd();
          }
        } else {
          print("Recording file not found: $_currentRecordingPath");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recording file not found!")),
          );
        }
      } else {
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
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(onThemeChanged: (v) {}),
        ),
            (route) => false,
      );
    } catch (e) {
      print("Logout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text('Voice Recorder', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                logout(context);
              } else if (value == 'forget') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: screenHeight * 0.12,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.1,
              vertical: screenHeight * 0.02,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navIcon(context, Icons.settings, () => _onBottomNavTap(0)),
                SizedBox(width: screenWidth * 0.15),
                _navIcon(context, Icons.folder, () => _onBottomNavTap(1)),
              ],
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.03,
            child: Container(
              height: screenHeight * 0.08,
              width: screenHeight * 0.08,
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
                  color: Colors.white,
                ),
                iconSize: screenHeight * 0.040,
                onPressed: isRecording
                    ? () => _stopRecording(save: true)
                    : _startRecording,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isBannerAdLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Flexible(
                              flex: 1,
                              child: SizedBox(height: screenHeight * 0.02),
                            ),
                            SizedBox(
                              height: screenHeight * 0.25,
                              child: GradientVisualizer(isActive: isRecording),
                            ),
                            Flexible(
                              flex: 1,
                              child: SizedBox(height: screenHeight * 0.02),
                            ),
                            Text(
                              isRecording ? _formatDuration(elapsed).substring(3) : '00:00',
                              style: TextStyle(
                                fontSize: screenHeight * 0.06,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              isRecording ? "Recording..." : "Ready to Record",
                              style: TextStyle(
                                color: isRecording ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: screenHeight * 0.022,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildRoundButton(
                                    context,
                                    Icons.close,
                                    "Discard",
                                    isRecording ? () => _stopRecording(save: false) : null,
                                  ),
                                  _buildRoundButton(
                                    context,
                                    Icons.check,
                                    "Save",
                                    isRecording ? () => _stopRecording(save: true) : null,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenHeight * 0.015),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).iconTheme.color,
          size: screenHeight * 0.03,
        ),
      ),
    );
  }

  Widget _buildRoundButton(
      BuildContext context, IconData icon, String label, VoidCallback? onTap) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: screenHeight * 0.065,
          width: screenHeight * 0.065,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap != null
                ? Theme.of(context).cardColor
                : Theme.of(context).cardColor?.withOpacity(0.5),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              size: screenHeight * 0.03,
              color: onTap != null
                  ? Theme.of(context).iconTheme.color
                  : Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onTap,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: onTap != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}




// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:record/record.dart';
// import 'package:voice_recorder/audio_model.dart';
// import 'package:voice_recorder/gradient_visualizer.dart';
// import 'package:voice_recorder/settings_screen.dart';
// import 'package:voice_recorder/shared_preferences.dart';
// import 'history_screen.dart';
//
// class RecorderScreen extends StatefulWidget {
//   const RecorderScreen({Key? key}) : super(key: key);
//
//   @override
//   State<RecorderScreen> createState() => _RecorderScreenState();
// }
//
// class _RecorderScreenState extends State<RecorderScreen> {
//   bool isRecording = false;
//   late Timer _timer;
//   Duration elapsed = Duration.zero;
//   List<String> fileList = [];
//   final AudioRecorder _recorder = AudioRecorder();
//   String? _currentRecordingPath;
//
//   @override
//   void dispose() {
//     if (_timer.isActive) _timer.cancel();
//     _recorder.dispose();
//     _bannerAd.dispose();
//     super.dispose();
//   }
//
//   late BannerAd _bannerAd;
//
//   bool _isBannerAdLoaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBannerAd();
//   }
//
//   void _loadBannerAd() {
//     _bannerAd = BannerAd(
//       adUnitId: 'ca-app-pub-3504876174710558/4802722730',
//       //adUnitId: 'ca-app-pub-3940256099942544/9214589741',
//       size: AdSize.banner,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (_) {
//           setState(() {
//             _isBannerAdLoaded = true;
//           });
//           print('Banner ad loaded successfully.');
//         },
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           print('Failed to load a banner ad: ${error.code} - ${error.message}');
//           if (error.code == 3) {
//             print('AdMob server did not return an ad due to "No fill".');
//             print('Possible reasons: low inventory, region restrictions, or new Ad Unit.');
//           }
//         },
//       ),
//     )..load();
//   }
//
//
//   Future<bool> _requestPermissions() async {
//     final status = await Permission.microphone.request();
//     return status == PermissionStatus.granted;
//   }
//
//   Future<String> _getRecordingPath() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final recordingsDir = Directory('${directory.path}/recordings');
//
//     if (!await recordingsDir.exists()) {
//       await recordingsDir.create(recursive: true);
//     }
//
//     final fileName = "audio_${DateTime.now().millisecondsSinceEpoch}.wav";
//     return '${recordingsDir.path}/$fileName';
//   }
//
//   void _startRecording() async {
//     // Request microphone permission
//     if (!await _requestPermissions()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Microphone permission is required!")),
//       );
//       return;
//     }
//
//     try {
//       // Get the recording path
//       _currentRecordingPath = await _getRecordingPath();
//
//       // Start recording
//       await _recorder.start(
//         const RecordConfig(
//           encoder: AudioEncoder.wav,
//           sampleRate: 44100,
//           bitRate: 128000,
//         ),
//         path: _currentRecordingPath!,
//       );
//
//       setState(() {
//         isRecording = true;
//         elapsed = Duration.zero;
//       });
//
//       _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         setState(() {
//           elapsed += const Duration(seconds: 1);
//         });
//       });
//
//       print("Recording started: $_currentRecordingPath");
//     } catch (e) {
//       print("Error starting recording: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error starting recording: $e")),
//       );
//     }
//   }
//
//   void _stopRecording({bool save = true}) async {
//     if (_timer.isActive) _timer.cancel();
//
//     final recordedDuration = elapsed;
//
//     try {
//       // Stop recording
//       await _recorder.stop();
//
//       setState(() {
//         isRecording = false;
//         elapsed = Duration.zero;
//       });
//
//       if (save && _currentRecordingPath != null) {
//         // Check if file exists
//         final file = File(_currentRecordingPath!);
//         if (await file.exists()) {
//           final fileName = _currentRecordingPath!.split('/').last;
//
//           final model = AudioModel(
//             fileName: fileName,
//             path: _currentRecordingPath!,
//             recordedAt: DateTime.now(),
//             duration: _formatDuration(recordedDuration).substring(3),
//           );
//
//           await StorageHelper.addRecording(model);
//
//           print("Recording saved: ${model.fileName} at ${model.path}");
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Recording saved!"), backgroundColor: Colors.black),
//           );
//         } else {
//           print("Recording file not found: $_currentRecordingPath");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Recording file not found!")),
//           );
//         }
//       } else {
//         // Delete the file if not saving
//         if (_currentRecordingPath != null) {
//           final file = File(_currentRecordingPath!);
//           if (await file.exists()) {
//             await file.delete();
//           }
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Recording discarded!"), backgroundColor: Colors.black),
//         );
//       }
//     } catch (e) {
//       print("Error stopping recording: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error stopping recording: $e")),
//       );
//     }
//
//     _currentRecordingPath = null;
//   }
//
//   String _formatDuration(Duration duration) {
//     return duration.toString().split('.').first.padLeft(8, "0");
//   }
//
//   void _onBottomNavTap(int index) {
//     if (index == 0) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => SettingsScreen()),
//       );
//     } else if (index == 1) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => HistoryScreen()),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Coming soon!")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Center(
//           child: Text('Voice Recorder', style: TextStyle(color: Colors.white)),
//         ),
//         backgroundColor: const Color(0xFF0B0620),
//       ),
//       backgroundColor: const Color(0xFF0B0620),
//       bottomNavigationBar: Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           Container(
//             height: 100,
//             decoration: const BoxDecoration(
//               color: Color(0xFF1E1550),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _navIcon(Icons.settings, () => _onBottomNavTap(0)),
//                 const SizedBox(width: 60),
//                 _navIcon(Icons.folder, () => _onBottomNavTap(1)),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 40,
//             child: Container(
//               height: 60,
//               width: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isRecording ? Colors.red : Colors.redAccent,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.red.withOpacity(0.6),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   )
//                 ],
//               ),
//               child: IconButton(
//                 icon: Icon(
//                     isRecording ? Icons.stop : Icons.mic,
//                     color: Colors.white
//                 ),
//                 iconSize: 36,
//                 onPressed: isRecording ? () => _stopRecording(save: true) : _startRecording,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 40),
//           // GradientVisualizer hamesha visible hai, lekin sirf recording time animate hota hai
//           GradientVisualizer(isActive: isRecording),
//           const SizedBox(height: 30),
//           // Timer text hamesha visible hai
//           Text(
//             isRecording ? _formatDuration(elapsed).substring(3) : '00:00',
//             style: const TextStyle(fontSize: 50, color: Colors.white),
//           ),
//           const SizedBox(height: 10),
//           // Recording status text hamesha visible hai
//           Text(
//             isRecording ? "Recording..." : "Ready to Record",
//             style: TextStyle(
//               color: isRecording ? Colors.red : Colors.grey,
//               fontSize: 18,
//             ),
//           ),
//           const Spacer(),
//           // Save/Discard buttons hamesha visible hain
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildRoundButton(
//                     Icons.close,
//                     "Discard",
//                     isRecording ? () => _stopRecording(save: false) : null
//                 ),
//                 _buildRoundButton(
//                     Icons.check,
//                     "Save",
//                     isRecording ? () => _stopRecording(save: true) : null
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 40),
//           if (_isBannerAdLoaded)
//             SizedBox(
//               height: _bannerAd.size.height.toDouble(),
//               width: _bannerAd.size.width.toDouble(),
//               child: AdWidget(ad: _bannerAd),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _navIcon(IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: const BoxDecoration(
//           shape: BoxShape.circle,
//           color: Color(0xFF0B0620),
//         ),
//         child: Icon(icon, color: Colors.white),
//       ),
//     );
//   }
//
//   Widget _buildRoundButton(IconData icon, String label, VoidCallback? onTap) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: onTap != null ? const Color(0xFF1E1550) : const Color(0xFF1E1550).withOpacity(0.5),
//           ),
//           child: IconButton(
//             icon: Icon(
//                 icon,
//                 color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5)
//             ),
//             onPressed: onTap,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//             label,
//             style: TextStyle(
//                 color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5)
//             )
//         ),
//       ],
//     );
//   }
// }