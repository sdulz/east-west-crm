enum RegisterSteps {
  step1,
  step2,
  step3;

  static const String step1Key = "STEP_1";
  static const String step2Key = "STEP_2";
  static const String step3Key = "STEP_3";

  @override
  String toString() {
    return switch (this) {
      RegisterSteps.step1 => step1Key,
      RegisterSteps.step2 => step2Key,
      RegisterSteps.step3 => step3Key,  
    };
  }

  String mapToUI() {
    return switch (this) {
      RegisterSteps.step1 => "Step 1",
      RegisterSteps.step2 => "Step 2",
      RegisterSteps.step3 => "Step 3",
    };
  }

  static RegisterSteps? fromJson(String? key) {
    switch (key?.toUpperCase()) {
      case step1Key:
        return RegisterSteps.step1;
      case step2Key:
        return RegisterSteps.step2;
      case step3Key:
        return RegisterSteps.step3;
      default:
        return null;
    }
  }
}
