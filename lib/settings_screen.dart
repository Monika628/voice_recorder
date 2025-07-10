import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  double _volume = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0620), // 🔵 Background color
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF1E1550), // 🟣 AppBar color
        foregroundColor: Colors.white, // AppBar text/icon color
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
              value: _isDarkMode,
              onChanged: (val) {
                setState(() {
                  _isDarkMode = val;
                });
              },
              activeColor: Colors.deepPurpleAccent,
              inactiveThumbColor: Colors.grey,
              tileColor: const Color(0xFF1E1550),
              thumbColor: MaterialStateProperty.all(Colors.white),
            ),

            const SizedBox(height: 20),
            Text(
              "Playback Volume: ${(_volume * 100).toInt()}%",
              style: const TextStyle(color: Colors.white),
            ),
            Slider(
              value: _volume,
              onChanged: (val) {
                setState(() {
                  _volume = val;
                });
              },
              min: 0,
              max: 1,
              divisions: 20, // 👈 5% increment steps
              activeColor: Colors.deepPurpleAccent,
              inactiveColor: Colors.grey,
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save settings or perform an action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings Saved!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1550),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("Save Settings"),
            )
          ],
        ),
      ),
    );
  }
}
