import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringListConverter', () {
    const StringListConverter converter = StringListConverter();

    test('encodes a list as a JSON array', () {
      expect(
        converter.toSql(<String>['fantasy', 'goth']),
        '["fantasy","goth"]',
      );
    });

    test('decodes a JSON array', () {
      expect(converter.fromSql('["fantasy","goth"]'), <String>[
        'fantasy',
        'goth',
      ]);
    });

    test('returns an empty list for empty or malformed values', () {
      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('not json'), isEmpty);
      expect(converter.fromSql('[]'), isEmpty);
    });

    test('ignores non-string and empty elements', () {
      expect(converter.fromSql('[1,"fantasy",null,""]'), <String>['fantasy']);
    });
  });
}
