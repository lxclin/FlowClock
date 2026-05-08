class BiometricSnapshot {
  final double hr;
  final double hrvRmssd;
  final double hrvSdnn;
  final DateTime timestamp;

  const BiometricSnapshot({
    required this.hr,
    required this.hrvRmssd,
    required this.hrvSdnn,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'hr': hr,
        'hrvRmssd': hrvRmssd,
        'hrvSdnn': hrvSdnn,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BiometricSnapshot.fromJson(Map<String, dynamic> json) {
    return BiometricSnapshot(
      hr: (json['hr'] as num).toDouble(),
      hrvRmssd: (json['hrvRmssd'] as num).toDouble(),
      hrvSdnn: (json['hrvSdnn'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  BiometricSnapshot copyWith({
    double? hr,
    double? hrvRmssd,
    double? hrvSdnn,
    DateTime? timestamp,
  }) {
    return BiometricSnapshot(
      hr: hr ?? this.hr,
      hrvRmssd: hrvRmssd ?? this.hrvRmssd,
      hrvSdnn: hrvSdnn ?? this.hrvSdnn,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
