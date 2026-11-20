import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecentColors', () {
    test('normalize accepts hex with or without a hash', () {
      expect(RecentColors.normalize('#ff0000'), '#FF0000');
      expect(RecentColors.normalize('00BCD4'), '#00BCD4');
      expect(RecentColors.normalize('  #ffffff  '), '#FFFFFF');
      expect(RecentColors.normalize('#FFF'), isNull);
      expect(RecentColors.normalize('#GGGGGG'), isNull);
    });

    test('sanitize drops invalid and duplicate values and caps the list', () {
      final List<String> result = RecentColors.sanitize(<String>[
        '#111111',
        'invalid',
        '#111111',
        '#222222',
        '#333333',
        '#444444',
        '#555555',
        '#666666',
        '#777777',
        '#888888',
        '#999999',
      ]);

      expect(result, <String>[
        '#111111',
        '#222222',
        '#333333',
        '#444444',
        '#555555',
        '#666666',
        '#777777',
        '#888888',
      ]);
    });

    test('remember moves an existing color to the front', () {
      expect(
        RecentColors.remember(
          <String>['#111111', '#222222', '#333333'],
          '#222222',
        ),
        <String>['#222222', '#111111', '#333333'],
      );
    });

    test('remember normalizes the new color and keeps only eight entries', () {
      final List<String> result = RecentColors.remember(
        <String>[
          '#111111',
          '#222222',
          '#333333',
          '#444444',
          '#555555',
          '#666666',
          '#777777',
          '#888888',
        ],
        'abcdef',
      );

      expect(result.first, '#ABCDEF');
      expect(result, hasLength(RecentColorsService.maxColors));
      expect(result.last, '#777777');
    });

    test('remember ignores invalid input', () {
      final List<String> colors = <String>['#111111', '#222222'];
      expect(
        RecentColors.remember(colors, 'not a color'),
        colors,
      );
    });
  });
}
