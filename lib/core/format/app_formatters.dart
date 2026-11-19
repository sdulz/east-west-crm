import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/env.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:intl/intl.dart';

/// Dates in the user's timezone, money in the configured currency.
class AppFormatters {
  const AppFormatters({required this.timezone, required this.locale});
  final String timezone;
  final String? locale;

  String money(double amount) => NumberFormat.currency(
    locale: locale,
    name: AppEnv.currencyCode,
    decimalDigits: 0,
  ).format(amount);

  String dateTime(DateTime utc) =>
      DateFormat.yMMMd(locale).add_jm().format(inZone(utc, timezone));

  String date(DateTime utc) =>
      DateFormat.yMMMd(locale).format(inZone(utc, timezone));

  String time(DateTime utc) =>
      DateFormat.jm(locale).format(inZone(utc, timezone));

  String weekday(DateTime utc) =>
      DateFormat.E(locale).format(inZone(utc, timezone));

  String weekdayTime(DateTime utc) =>
      DateFormat.E(locale).add_jm().format(inZone(utc, timezone));
}

final formattersProvider = Provider<AppFormatters>((ref) => AppFormatters(
  timezone: ref.watch(currentUserProvider)?.timezone ?? 'UTC',
  locale: Intl.defaultLocale,
));
