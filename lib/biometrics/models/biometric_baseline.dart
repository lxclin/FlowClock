class BiometricBaseline {
  final double restingHr;
  final double restingHrvRmssd;
  final double restingHrvSdnn;
  final double hrvRmssdStd;
  final DateTime calibratedAt;

  const BiometricBaseline({
    required this.restingHr,
    required this.restingHrvRmssd,
    required this.restingHrvSdnn,
    required this.hrvRmssdStd,
    required this.calibratedAt,
  });

  Map<String, dynamic> toJson() => {
        'restingHr': restingHr,
        'restingHrvRmssd': restingHrvRmssd,
        'restingHrvSdnn': restingHrvSdnn,
        'hrvRmssdStd': hrvRmssdStd,
        'calibratedAt': calibratedAt.toIso8601String(),
      };

  factory BiometricBaseline.fromJson(Map<String, dynamic> json) {
    return BiometricBaseline(
      restingHr: (json['restingHr'] as num).toDouble(),
      restingHrvRmssd: (json['restingHrvRmssd'] as num).toDouble(),
      restingHrvSdnn: (json['restingHrvSdnn'] as num).toDouble(),
      hrvRmssdStd: (json['hrvRmssdStd'] as num).toDouble(),
      calibratedAt: DateTime.parse(json['calibratedAt'] as String),
    );
  }

  static final defaults = BiometricBaseline(
    restingHr: 65.0,
    restingHrvRmssd: 42.0,
    restingHrvSdnn: 53.0,
    hrvRmssdStd: 8.0,
    calibratedAt: _dummy,
  );

  static final _dummy = DateTime(2024, 1, 1);
}
