import 'package:timezone/timezone.dart' as tz;

/// Injectable time source so dashboards and reminders are testable.
class Clock {
  const Clock();
  DateTime now() => DateTime.now().toUtc();
}

class FixedClock implements Clock {
  const FixedClock(this.fixed);
  final DateTime fixed;
  @override
  DateTime now() => fixed;
}

/// Converts a UTC instant to a wall-clock [tz.TZDateTime] in [zoneId].
/// Falls back to UTC when the zone is unknown so the UI never crashes.
tz.TZDateTime inZone(DateTime utc, String zoneId) {
  tz.Location loc;
  try {
    loc = tz.getLocation(zoneId);
  } on Object {
    loc = tz.UTC;
  }
  return tz.TZDateTime.from(utc, loc);
}

/// Start of the local day for [utc] in [zoneId], returned as UTC.
DateTime startOfDay(DateTime utc, String zoneId) {
  final local = inZone(utc, zoneId);
  return tz.TZDateTime(
    local.location,
    local.year,
    local.month,
    local.day,
  ).toUtc();
}
