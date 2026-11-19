enum TestType {
  quiz,
  practice,
  test;

  static const String quizKey = "QUIZ";
  static const String practiceKey = "PRACTICE";
  static const String testKey = "TEST";

  @override
  String toString() {
    return switch (this) {
      TestType.quiz => quizKey,
      TestType.practice => practiceKey,
      TestType.test => testKey,
    };
  }

  String mapToUI() {
    return switch (this) {
      TestType.quiz => "Quiz",
      TestType.practice => "Practice",
      TestType.test => "Test",
    };
  }

  static TestType fromJson(String key) {
    switch (key.toUpperCase()) {
      case quizKey:
        return TestType.quiz;
      case practiceKey:
        return TestType.practice;
      case testKey:
        return TestType.test;
      default:
        return TestType.quiz;
    }
  }
}
