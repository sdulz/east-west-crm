enum ShiftEnums {
  morning,
  day,
  evening,
  night;

  static const String morningKey = "MORNING";
  static const String dayKey = "DAY";
  static const String eveningKey = "EVENING";
  static const String nightKey = "NIGHT";

  @override
  String toString() {
    return switch (this) {
      ShiftEnums.morning => morningKey,
      ShiftEnums.day => dayKey,
      ShiftEnums.evening => eveningKey,
      ShiftEnums.night => nightKey,
    };
  }

  String mapToUI() {
    return switch (this) {
      ShiftEnums.morning => "Morning",
      ShiftEnums.day => "Day",
      ShiftEnums.evening => "Evening",
      ShiftEnums.night => "Night",
    };
  }

  static ShiftEnums? fromJson(String? key) {
    switch (key?.toUpperCase()) {
      case morningKey:
        return ShiftEnums.morning;
      case dayKey:
        return ShiftEnums.day;
      case eveningKey:
        return ShiftEnums.evening;
      case nightKey:
        return ShiftEnums.night;
      default:
        return null;
    }
  }
}
