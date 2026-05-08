enum MentalState { normal, flow, fatigue }

extension MentalStateX on MentalState {
  String get label {
    switch (this) {
      case MentalState.normal:
        return '正常';
      case MentalState.flow:
        return '心流';
      case MentalState.fatigue:
        return '疲劳';
    }
  }
}
