import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Redacting logger. Never use print(). Everything passes through [redact]
/// before it reaches the console or Sentry breadcrumbs.
class AppLogger {
  const AppLogger(this.tag);

  final String tag;

  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final _phone = RegExp(r'\+?\d[\d\s-]{6,}\d');
  static final _secret = RegExp(
    r'(token|key|password|secret)(["\s:=]+)[^\s,"}]+',
    caseSensitive: false,
  );

  static String redact(String input) => input
      .replaceAll(_email, '<email>')
      .replaceAll(_phone, '<phone>')
      .replaceAllMapped(_secret, (m) => '${m[1]}${m[2]}<redacted>');

  void info(String message) => _log(message, level: 800);

  void warn(String message) => _log(message, level: 900);

  void error(String message, [Object? error, StackTrace? stack]) {
    _log(
      '$message ${error == null ? '' : redact(error.toString())}',
      level: 1000,
      stack: stack,
    );
  }

  void _log(String message, {required int level, StackTrace? stack}) {
    final safe = redact(message);
    if (kDebugMode) {
      dev.log(safe, name: tag, level: level, stackTrace: stack);
    }
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(message: safe, category: tag, level: _sentryLevel(level)),
      ),
    );
  }

  SentryLevel _sentryLevel(int level) => switch (level) {
    >= 1000 => SentryLevel.error,
    >= 900 => SentryLevel.warning,
    _ => SentryLevel.info,
  };
}
