import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';

/// "Server-side" validation. Messages are shown verbatim in the UI.
abstract final class MockValidation {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _phone = RegExp(r'^\+?[0-9][0-9 -]{6,17}[0-9]$');

  static void required(String? v, String field, String label) {
    if (v == null || v.trim().isEmpty) {
      throw MockFailure(Failure.validation('$label is required', field: field));
    }
  }

  static void email(String? v) {
    if (v != null && v.isNotEmpty && !_email.hasMatch(v)) {
      throw const MockFailure(
        Failure.validation(
          'Email must look like name@example.com',
          field: 'email',
        ),
      );
    }
  }

  static void phone(String? v) {
    if (v != null && v.isNotEmpty && !_phone.hasMatch(v)) {
      throw const MockFailure(
        Failure.validation(
          'Phone must be digits with optional +, spaces or dashes '
          '(e.g. +977 98XXXXXXXX)',
          field: 'phone',
        ),
      );
    }
  }

  static void range(num v, num min, num max, String field, String label) {
    if (v < min || v > max) {
      throw MockFailure(
        Failure.validation(
          '$label must be between $min and $max',
          field: field,
        ),
      );
    }
  }

  static void conflict(DateTime actual, DateTime expected) {
    if (actual.toUtc() != expected.toUtc()) {
      throw const MockFailure(Failure.conflict());
    }
  }
}
