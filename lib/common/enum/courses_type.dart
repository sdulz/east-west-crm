import 'package:field_crm/common/constant/image_constant.dart';

enum CoursesType {
  physics,
  chemistry,
  botany,
  mat,
  deepnotes,
  zoology;

  static const String physicsKey = "PHYSICS";
  static const String chemistryKey = "CHEMISTRY";
  static const String botanyKey = "BOTANY";
  static const String matKey = "MAT";
  static const String deepnotesKey = "DEEP_NOTES";
  static const String zoologyKey = "ZOOLOGY";

  @override
  String toString() {
    return switch (this) {
      CoursesType.physics => physicsKey,
      CoursesType.chemistry => chemistryKey,
      CoursesType.botany => botanyKey,
      CoursesType.mat => matKey,
      CoursesType.deepnotes => deepnotesKey,
      CoursesType.zoology => zoologyKey,
    };
  }

  String mapToUI() {
    return switch (this) {
      CoursesType.physics => "Physics",
      CoursesType.chemistry => "Chemistry",
      CoursesType.botany => "Botany",
      CoursesType.mat => "MAT",
      CoursesType.deepnotes => "Deep Notes",
      CoursesType.zoology => "Zoology",
    };
  }

  static CoursesType? fromJson(String? key) {
    switch (key?.toUpperCase()) {
      case physicsKey:
        return CoursesType.physics;
      case chemistryKey:
        return CoursesType.chemistry;
      case botanyKey:
        return CoursesType.botany;
      case matKey:
        return CoursesType.mat;
      case deepnotesKey:
        return CoursesType.deepnotes;
      case zoologyKey:
        return CoursesType.zoology;
      default:
        return null;
    }
  }
}


extension CoursesTypeImage on CoursesType {
  String get image {
    return switch (this) {
      CoursesType.physics => ImageConstants.physics,
      CoursesType.chemistry => ImageConstants.chemistry,
      CoursesType.botany => ImageConstants.botany,
      CoursesType.mat => ImageConstants.mat,
      CoursesType.deepnotes => ImageConstants.deepnotes,
      CoursesType.zoology => ImageConstants.zoology,
    };
  }
}
