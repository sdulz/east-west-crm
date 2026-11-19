enum TestSeriesEnum {
  all,
  upcoming,
  ongoing,
  completed;

  static const String allKey = 'ALL';
  static const String upcomingKey = 'UPCOMING';
  static const String ongoingKey = 'ONGOING';
  static const String completedKey = 'COMPLETED';
  @override
  String toString() {
    return switch (this) {
      TestSeriesEnum.all => allKey,
      TestSeriesEnum.upcoming => upcomingKey,
      TestSeriesEnum.ongoing => ongoingKey,
      TestSeriesEnum.completed => completedKey,
    };
  }

  String toJson() => toString();

  String mapToUI() {
    return switch (this) {
      TestSeriesEnum.all => 'All',
      TestSeriesEnum.upcoming => 'Upcoming',
      TestSeriesEnum.ongoing => 'Ongoing',
      TestSeriesEnum.completed => 'Completed',
    };
  }
}
