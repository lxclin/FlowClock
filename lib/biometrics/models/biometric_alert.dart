import 'mental_state.dart';

class BiometricAlert {
  final MentalState state;
  final double hr;
  final double hrvRmssd;
  final DateTime timestamp;

  const BiometricAlert({
    required this.state,
    required this.hr,
    required this.hrvRmssd,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'hr': hr,
        'hrvRmssd': hrvRmssd,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BiometricAlert.fromJson(Map<String, dynamic> json) {
    return BiometricAlert(
      state: MentalState.values.firstWhere((e) => e.name == json['state']),
      hr: (json['hr'] as num).toDouble(),
      hrvRmssd: (json['hrvRmssd'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
