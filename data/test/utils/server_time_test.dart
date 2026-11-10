import 'package:data/src/utils/server_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseServerTimestamp', () {
    final DateTime expected = DateTime.utc(2026, 11, 10, 9, 31, 14, 263);

    test('treats a timestamp without an offset as UTC', () {
      final DateTime parsed = parseServerTimestamp('2026-11-10T09:31:14.263');

      expect(parsed, expected);
      expect(parsed.isUtc, isTrue);
    });

    test('keeps a UTC timestamp with a Z suffix', () {
      expect(
        parseServerTimestamp('2026-11-10T09:31:14.263Z'),
        expected,
      );
    });

    test('keeps an explicit UTC offset', () {
      expect(
        parseServerTimestamp('2026-11-10T09:31:14.263+00:00'),
        expected,
      );
    });

    test('converts a non-UTC offset to the same moment', () {
      expect(
        parseServerTimestamp('2026-11-10T12:31:14.263+03:00'),
        expected,
      );
    });
  });
}
