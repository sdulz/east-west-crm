enum CoursesEnums {
  syllabus,
  notes,
  videos,
  liveClassVideos,
  ebooks;

  static const String syllabusKey = "SYLLABUS";
  static const String notesKey = "NOTES";
  static const String videosKey = "VIDEOS";
  static const String liveClassVideosKey = "LIVE_CLASS_VIDEOS";
  static const String ebooksKey = "EBOOKS";

  @override
  String toString() {
    return switch (this) {
      CoursesEnums.syllabus => syllabusKey,
      CoursesEnums.notes => notesKey,
      CoursesEnums.videos => videosKey,
      CoursesEnums.liveClassVideos => liveClassVideosKey,
      CoursesEnums.ebooks => ebooksKey,
    };
  }

  String mapToUI() {
    return switch (this) {
      CoursesEnums.syllabus => "Syllabus",
      CoursesEnums.notes => "Notes",
      CoursesEnums.videos => "Videos",
      CoursesEnums.liveClassVideos => "Live Class Videos",
      CoursesEnums.ebooks => "Ebooks",
    };
  }

  static CoursesEnums? fromJson(String? key) {
    switch (key?.toUpperCase()) {
      case syllabusKey:
        return CoursesEnums.syllabus;
      case notesKey:
        return CoursesEnums.notes;
      case videosKey:
        return CoursesEnums.videos;
      case liveClassVideosKey:
        return CoursesEnums.liveClassVideos;
      case ebooksKey:
        return CoursesEnums.ebooks;
      default:
        return null;
    }
  }
}
