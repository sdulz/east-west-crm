enum BannerEnum {
  primary,
  secondary;

  static const String primaryKey = "PRIMARY";
  static const String secondaryKey = "SECONDARY";

  @override
  String toString() {
    return switch (this) {
      BannerEnum.primary => primaryKey,
      BannerEnum.secondary => secondaryKey,
    };
  }


  String toJson() => toString();
}
