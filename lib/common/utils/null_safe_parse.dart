import 'package:intl/intl.dart';

String _defaultAlternative() => "-";

String nullSafeParse(Object? object, [String? alternative]) {
  if (object == null || (object is bool && object == false)) {
    return alternative ?? _defaultAlternative();
  }
  return object.toString();
}

String nullSafeNAParse(Object? object) {
  return nullSafeParse(object, "-");
}

String nullEmptySafeParse(Object? object, [String? alternative]) {
  final value = nullSafeParse(object, alternative);
  if (value.isEmpty) {
    return alternative ?? _defaultAlternative();
  } else {
    return value;
  }
}

num nullSafeNumParse(Object? object, [num alternative = 0]) {
  final objectString = object?.toString();
  if (object == null || objectString == 'false') {
    return alternative;
  }

  return num.parse(
    ((num.tryParse(objectString ?? "")) ?? alternative).toStringAsFixed(2),
  );
}

int nullSafeIntParse(Object? object, [num alternative = 0]) {
  final objectString = object?.toString();
  if (object == null || objectString == 'false') {
    return alternative.toInt();
  }

  return int.parse(
    ((int.tryParse(objectString ?? "")) ?? alternative).toString(),
  );
}

DateTime nullSafeDateParse(Object? object, [DateTime? alternative]) {
  if (object is bool && object == false) {
    object = null;
  }

  return DateTime.tryParse(object?.toString() ?? "") ??
      alternative ??
      DateTime.now();
}

DateTime? mayParseDateTime(Object? object) {
  if (object is bool && object == false) {
    return null;
  }
  return DateTime.tryParse(object?.toString() ?? "");
}


String nullSafeStringDateParse(Object? object, [DateTime? alternative]) {
  return DateFormat(
    "yyyy-MM-dd",
  ).format(nullSafeDateParse(object, alternative));
}

String? mayParseStringDateTime(Object? object) {
  final value = mayParseDateTime(object);
  if (value == null) {
    return null;
  }
  return DateFormat("yyyy-MM-dd").format(value);
}

T? parseObjectOrNull<T>(Object? object, T Function(Object object) parse) {
  if (object == null || (object is bool && object == false)) return null;
  return parse(object);
}

T parseObjectOr<T>(
  Object? object,
  T Function(Object object) parse,
  T alternative,
) {
  if (object == null || (object is bool && object == false)) return alternative;
  return parse(object);
}
