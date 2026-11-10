/// Parses a timestamp returned by Supabase as a UTC moment.
///
/// Monetization timestamps are stored as `timestamptz` and normally arrive
/// with a `Z` or a numeric offset. Older rows and cached values can still omit
/// the zone; those were always written in UTC, so appending `Z` keeps
/// comparisons with `DateTime.now()` correct regardless of the device
/// timezone.
DateTime parseServerTimestamp(String value) {
  final bool hasTimeZone =
      value.endsWith('Z') || RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(value);
  return DateTime.parse(hasTimeZone ? value : '${value}Z');
}

/// Current UTC moment formatted for comparisons with server timestamps.
String serverNowIso8601() => DateTime.now().toUtc().toIso8601String();
