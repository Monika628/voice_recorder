class AudioModel {
  final String path;
  final DateTime recordedAt;
  final String fileName;
  final String duration;

  AudioModel({
    required this.path,
    required this.recordedAt,
    required this.fileName,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'recordedAt': recordedAt.toIso8601String(),
    'fileName': fileName,
    'duration': duration,
  };

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      path: json['path'] ?? '',
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt']) ?? DateTime.now()
          : DateTime.now(),
      fileName: json['fileName'] ?? 'Untitled.aac',
      duration: json['duration'] ?? '0:00',
    );
  }
}
