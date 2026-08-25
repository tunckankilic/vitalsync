/// VitalSync — Remote payload helpers.
///
/// Columns that hold JSON (a tag array, a counter map) are pushed to the cloud
/// as the decoded structure, because the sync payload is built from a model's
/// `toJson()`. The same value can also arrive already encoded — an older
/// client, or a record written straight from a Drift row. These helpers accept
/// both shapes so a round trip cannot fail on a type cast.
library;

import 'dart:convert';

/// Returns [value] as a JSON string suitable for a text column.
///
/// Accepts an already-encoded string or a decoded List/Map; falls back to
/// [fallback] when the value is null or of an unexpected type.
String encodeJsonColumn(Object? value, {required String fallback}) {
  if (value == null) return fallback;
  if (value is String) return value.isEmpty ? fallback : value;
  if (value is List || value is Map) return jsonEncode(value);
  return fallback;
}
