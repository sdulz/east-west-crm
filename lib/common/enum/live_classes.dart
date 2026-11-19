enum LiveClasses {
  all,
  upcoming,
  past,
  live,
  today;

  static const String allKey = 'ALL';
  static const String liveKey = 'LIVE';
  static const String upcomingKey = 'UPCOMING';
  static const String pastKey = 'PAST';
  static const String todayKey = 'TODAY';

  /// Values visible in the UI filter — `today` is internal-only.
  static List<LiveClasses> get uiFilterValues => [
    LiveClasses.all,
    LiveClasses.today,
    LiveClasses.live,
    LiveClasses.past,
  ];

  @override
  String toString() {
    return switch (this) {
      LiveClasses.all => allKey,
      LiveClasses.live => liveKey,
      LiveClasses.upcoming => upcomingKey,
      LiveClasses.past => pastKey,
      LiveClasses.today => todayKey,
    };
  }

  String toJson() => toString();

  String mapToUI() {
    return switch (this) {
      LiveClasses.all => 'All',
      LiveClasses.live => 'Live',
      LiveClasses.upcoming => 'Upcoming',
      LiveClasses.past => 'Past',
      LiveClasses.today => 'Today',
    };
  }

  static LiveClasses? fromJson(String? key) {
    switch (key?.toUpperCase()) {
      case allKey:
        return LiveClasses.all;
      case liveKey:
        return LiveClasses.live;
      case upcomingKey:
        return LiveClasses.upcoming;
      case pastKey:
        return LiveClasses.past;
      default:
        return null;
    }
  }
}
