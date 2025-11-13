import 'package:flutter/material.dart';
import 'package:voice_recorder/settings_storage.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const SettingsScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  double _playbackVolume = 0.5;
  double _recordingVolume = 0.5;
  String _audioQuality = 'High';
  String _recordingFormat = 'WAV';
  bool _autoSaveRecordings = true;
  bool _backgroundRecording = false;
  bool _showRecordingTimer = true;
  int _maxRecordingDuration = 60;

  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      _isDarkMode = await SettingsStorage.getBool('isDarkMode') ?? false;
      _playbackVolume = await SettingsStorage.getDouble('playbackVolume') ?? 0.5;
      _recordingVolume = await SettingsStorage.getDouble('recordingVolume') ?? 0.5;
      _audioQuality = await SettingsStorage.getString('audioQuality') ?? 'High';
      _recordingFormat = await SettingsStorage.getString('recordingFormat') ?? 'WAV';
      _autoSaveRecordings = await SettingsStorage.getBool('autoSaveRecordings') ?? true;
      _backgroundRecording = await SettingsStorage.getBool('backgroundRecording') ?? false;
      _showRecordingTimer = await SettingsStorage.getBool('showRecordingTimer') ?? true;
      _maxRecordingDuration = await SettingsStorage.getInt('maxRecordingDuration') ?? 60;
    } catch (e) {
      print('Error loading settings: $e');
      _showSnackBar(
        message: 'Failed to load settings',
        icon: Icons.error_outline,
        backgroundColor: Colors.orange,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await SettingsStorage.saveBool('isDarkMode', _isDarkMode);
      await SettingsStorage.saveDouble('playbackVolume', _playbackVolume);
      await SettingsStorage.saveDouble('recordingVolume', _recordingVolume);
      await SettingsStorage.saveString('audioQuality', _audioQuality);
      await SettingsStorage.saveString('recordingFormat', _recordingFormat);
      await SettingsStorage.saveBool('autoSaveRecordings', _autoSaveRecordings);
      await SettingsStorage.saveBool('backgroundRecording', _backgroundRecording);
      await SettingsStorage.saveBool('showRecordingTimer', _showRecordingTimer);
      await SettingsStorage.saveInt('maxRecordingDuration', _maxRecordingDuration);

      setState(() => _hasUnsavedChanges = false);

      _showSnackBar(
        message: 'Settings saved successfully! ✓',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print('Error saving settings: $e');
      _showSnackBar(
        message: 'Failed to save settings',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
      );
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              "Reset Settings",
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineSmall?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to reset all settings to default?\n\nThis action cannot be undone.",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Reset All"),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    try {
      await SettingsStorage.clearAll();

      setState(() {
        _isDarkMode = false;
        _playbackVolume = 0.5;
        _recordingVolume = 0.5;
        _audioQuality = 'High';
        _recordingFormat = 'WAV';
        _autoSaveRecordings = true;
        _backgroundRecording = false;
        _showRecordingTimer = true;
        _maxRecordingDuration = 60;
        _hasUnsavedChanges = false;
      });

      if (widget.onThemeChanged != null) {
        widget.onThemeChanged!(_isDarkMode);
      }

      _showSnackBar(
        message: 'Settings reset to defaults',
        icon: Icons.refresh,
        backgroundColor: Colors.blue,
      );
    } catch (e) {
      print('Error resetting settings: $e');
      _showSnackBar(
        message: 'Failed to reset settings',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _getQualityDescription(String quality) {
    switch (quality) {
      case 'Low':
        return '64 kbps - Smaller file size';
      case 'Medium':
        return '128 kbps - Balanced';
      case 'High':
        return '192 kbps - Better quality';
      case 'Very High':
        return '320 kbps - Best quality';
      default:
        return '';
    }
  }

  String _getFormatDescription(String format) {
    switch (format) {
      case 'MP3':
        return 'Compressed - Universal compatibility';
      case 'WAV':
        return 'Uncompressed - Highest quality';
      case 'AAC':
        return 'Compressed - Good quality';
      case 'M4A':
        return 'Compressed - Apple devices';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Loading settings...',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Unsaved',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: "Appearance",
                    icon: Icons.palette_outlined,
                  ),
                  _buildSwitchTile(
                    title: "Dark Mode",
                    subtitle: "Switch between light and dark theme",
                    icon: Icons.dark_mode_outlined,
                    value: _isDarkMode,
                    onChanged: (val) {
                      setState(() => _isDarkMode = val);
                      _markAsChanged();
                      if (widget.onThemeChanged != null) {
                        widget.onThemeChanged!(val);
                      }
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  _buildSectionHeader(
                    title: "Audio Settings",
                    icon: Icons.volume_up_outlined,
                  ),
                  _buildVolumeSlider(
                    title: "Playback Volume",
                    subtitle: "Volume when playing recordings",
                    icon: Icons.play_circle_outline,
                    value: _playbackVolume,
                    onChanged: (val) {
                      setState(() => _playbackVolume = val);
                      _markAsChanged();
                    },
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  _buildVolumeSlider(
                    title: "Recording Volume",
                    subtitle: "Microphone sensitivity level",
                    icon: Icons.mic_outlined,
                    value: _recordingVolume,
                    onChanged: (val) {
                      setState(() => _recordingVolume = val);
                      _markAsChanged();
                    },
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  _buildDropdown(
                    context: context,
                    title: "Audio Quality",
                    subtitle: _getQualityDescription(_audioQuality),
                    icon: Icons.high_quality_outlined,
                    value: _audioQuality,
                    items: ['Low', 'Medium', 'High', 'Very High'],
                    onChanged: (val) {
                      setState(() => _audioQuality = val!);
                      _markAsChanged();
                    },
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  _buildDropdown(
                    context: context,
                    title: "Recording Format",
                    subtitle: _getFormatDescription(_recordingFormat),
                    icon: Icons.audio_file_outlined,
                    value: _recordingFormat,
                    items: ['MP3', 'WAV', 'AAC', 'M4A'],
                    onChanged: (val) {
                      setState(() => _recordingFormat = val!);
                      _markAsChanged();
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  _buildSectionHeader(
                    title: "Recording Options",
                    icon: Icons.settings_outlined,
                  ),
                  _buildSwitchTile(
                    title: "Auto-save Recordings",
                    subtitle: "Automatically save when recording stops",
                    icon: Icons.save_outlined,
                    value: _autoSaveRecordings,
                    onChanged: (val) {
                      setState(() => _autoSaveRecordings = val);
                      _markAsChanged();
                    },
                  ),

                  _buildSwitchTile(
                    title: "Background Recording",
                    subtitle: "Continue recording when app is minimized",
                    icon: Icons.phonelink_outlined,
                    value: _backgroundRecording,
                    onChanged: (val) {
                      setState(() => _backgroundRecording = val);
                      _markAsChanged();
                    },
                  ),

                  _buildSwitchTile(
                    title: "Show Recording Timer",
                    subtitle: "Display elapsed time during recording",
                    icon: Icons.timer_outlined,
                    value: _showRecordingTimer,
                    onChanged: (val) {
                      setState(() => _showRecordingTimer = val);
                      _markAsChanged();
                    },
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  _buildNumberSetting(
                    title: "Max Recording Duration",
                    subtitle: "Maximum length for single recording",
                    icon: Icons.access_time,
                    value: _maxRecordingDuration,
                    unit: "minutes",
                    min: 1,
                    max: 180,
                    onChanged: (val) {
                      setState(() => _maxRecordingDuration = val);
                      _markAsChanged();
                    },
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  Center(
                    child: Container(
                      width: double.infinity,
                      height: screenHeight * 0.065,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: _hasUnsavedChanges
                            ? const LinearGradient(
                          colors: [Colors.redAccent, Colors.red],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                            : null,
                        color: _hasUnsavedChanges ? null : Colors.grey,
                        boxShadow: _hasUnsavedChanges
                            ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _hasUnsavedChanges ? _saveSettings : null,
                        icon: const Icon(Icons.save, size: 20),
                        label: Text(
                          _hasUnsavedChanges ? "Save Changes" : "No Changes",
                          style: TextStyle(
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  Center(
                    child: TextButton.icon(
                      onPressed: _showResetDialog,
                      icon: const Icon(Icons.restore, size: 18),
                      label: Text(
                        "Reset to Defaults",
                        style: TextStyle(
                          fontSize: screenHeight * 0.018,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Unsaved Changes",
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "You have unsaved changes. Do you want to save them before leaving?",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Discard"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveSettings();
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: value ? Theme.of(context).primaryColor : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontSize: 12,
          ),
        )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(value * 100).toInt()}%",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
              divisions: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).iconTheme.color,
              ),
              underline: const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required String unit,
    required int min,
    required int max,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: value > min
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.remove,
                    color: value > min
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 20,
                  ),
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                  splashRadius: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  "$value $unit",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: value < max
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: value < max
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 20,
                  ),
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}