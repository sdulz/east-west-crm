import 'package:field_crm/app/env.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_formatters.g.dart';

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

  String weekdayTime(DateTime utc) =>
      DateFormat.E(locale).add_jm().format(inZone(utc, timezone));
}

@riverpod
AppFormatters formatters(Ref ref) => AppFormatters(
  timezone: ref.watch(currentUserProvider)?.timezone ?? 'UTC',
  locale: Intl.defaultLocale,
);
