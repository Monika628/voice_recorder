import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_recorder/auth_provider.dart';
import 'package:voice_recorder/auth_service.dart';
import 'package:voice_recorder/firebase_options.dart';
import 'package:voice_recorder/login_screen.dart';
import 'package:voice_recorder/recorder_screen.dart';
import 'package:voice_recorder/settings_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e, stackTrace) {
    print("❌ Firebase initialization error: $e");
    print("Stack trace: $stackTrace");
  }

  try {
    await MobileAds.instance.initialize();
    print("✅ Google Mobile Ads initialized successfully");
  } catch (e) {
    print("❌ Google Mobile Ads initialization error: $e");
  }

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadThemeSettings();
    _checkFirebaseStatus();
  }

  // Add Firebase status check
  void _checkFirebaseStatus() {
    try {
      if (Firebase.apps.isNotEmpty) {
        print(" Firebase apps available: ${Firebase.apps.length}");
        print(" Default app: ${Firebase.app().name}");
      } else {
        print(" No Firebase apps found");
      }
    } catch (e) {
      print(" Firebase status check error: $e");
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = loggedIn;
    });
  }

  Future<void> _loadThemeSettings() async {
    final isDark = await SettingsStorage.getBool('isDarkMode') ?? false;
    setState(() {
      _isDarkMode = isDark;
      _isLoading = false;
    });
  }

  Future<void> updateTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
  }



  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until theme loads
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => AuthProvider(AuthService()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Voice Recorder',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: _isLoggedIn
            ? RecorderScreen(onThemeChanged: updateTheme)
            : LoginScreen(onThemeChanged: updateTheme),
      ),
    );

  }

  // Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: Colors.grey[100],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
        headlineSmall:
        TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.deepPurple),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.deepPurple;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  // Dark Theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.deepPurpleAccent,
      scaffoldBackgroundColor: const Color(0xFF0B0620),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1550),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF1E1550),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.grey),
        headlineSmall:
        TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.white),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.deepPurpleAccent;
          }
          return Colors.grey;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.deepPurpleAccent;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
      ),
    );
  }
}

//
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:voice_recorder/recorder_screen.dart';
//
// void main() async{
//   WidgetsFlutterBinding.ensureInitialized();
//   await MobileAds.instance.initialize();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: RecorderScreen(),
//     );
//   }
// }