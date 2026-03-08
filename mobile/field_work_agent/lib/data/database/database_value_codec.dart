class DatabaseValueCodec {
  const DatabaseValueCodec._();

  static DateTime? dateTimeOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.parse(value as String);
  }

  static DateTime dateTime(Object? value) {
    final parsed = dateTimeOrNull(value);
    if (parsed == null) {
      throw StateError('Expected a non-null DateTime value.');
    }
    return parsed;
  }

  static String? stringOrNull(Object? value) => value as String?;

  static String string(Object? value) {
    final parsed = stringOrNull(value);
    if (parsed == null) {
      throw StateError('Expected a non-null String value.');
    }
    return parsed;
  }

  static int? intOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.parse(value.toString());
  }

  static double? doubleOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }

  static bool boolFromSql(Object? value) {
    if (value is bool) {
      return value;
    }
    return intOrNull(value) == 1;
  }

  static int boolToSql(bool value) => value ? 1 : 0;
}