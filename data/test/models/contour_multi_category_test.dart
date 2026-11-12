import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContourModel Multi-Category Parsing & Mapping', () {
    test('1. parses categories array when present in JSON', () {
      final json = <String, dynamic>{
        'id': 'c1',
        'title': 'Dragon',
        'categories': ['fantasy', 'animals'],
        'svg_data': 'https://example.com/c1.svg',
        'preview_url': 'https://example.com/c1.png',
      };

      final model = ContourModel.fromJson(json);
      expect(
        model.categories,
        containsAll([ContourCategory.fantasy, ContourCategory.animals]),
      );
      expect(model.category, ContourCategory.fantasy);
    });

    test(
      '2. falls back to single category when categories array is absent or empty',
      () {
        final json = <String, dynamic>{
          'id': 'c2',
          'title': 'Wolf',
          'category': 'animals',
          'svg_data': 'https://example.com/c2.svg',
          'preview_url': 'https://example.com/c2.png',
        };

        final model = ContourModel.fromJson(json);
        expect(model.categories, [ContourCategory.animals]);
        expect(model.category, ContourCategory.animals);
      },
    );

    test('2b. ignores unknown categories and keeps known ones', () {
      final json = <String, dynamic>{
        'id': 'c2b',
        'title': 'Dragon',
        'categories': ['fantasy', 'goth', 'animals'],
        'svg_data': 'https://example.com/c2b.svg',
        'preview_url': 'https://example.com/c2b.png',
      };

      final model = ContourModel.fromJson(json);
      expect(model.categories, [
        ContourCategory.fantasy,
        ContourCategory.animals,
      ]);
    });

    test('2c. ignores the UI-only all value in stored categories', () {
      final json = <String, dynamic>{
        'id': 'c2c',
        'title': 'Dragon',
        'categories': ['all', 'fantasy'],
        'svg_data': 'https://example.com/c2c.svg',
        'preview_url': 'https://example.com/c2c.png',
      };

      final model = ContourModel.fromJson(json);
      expect(model.categories, [ContourCategory.fantasy]);
    });

    test(
      '3. falls back to ContourCategory.all when both categories and category are missing',
      () {
        final json = <String, dynamic>{
          'id': 'c3',
          'title': 'Unknown',
          'svg_data': 'https://example.com/c3.svg',
          'preview_url': 'https://example.com/c3.png',
        };

        final model = ContourModel.fromJson(json);
        expect(model.categories, [ContourCategory.all]);
        expect(model.category, ContourCategory.all);
      },
    );

    test(
      '4. toJson includes both categories array and legacy category string',
      () {
        const model = ContourModel(
          id: 'c4',
          title: 'Flower',
          categories: [ContourCategory.flowers, ContourCategory.nature],
          svgUrl: 'https://example.com/c4.svg',
          previewUrl: 'https://example.com/c4.png',
        );

        final json = model.toJson();
        expect(json['category'], 'flowers');
        expect(json['categories'], ['flowers', 'nature']);
      },
    );

    test('5. ContourMapper maps categories to entity and back', () {
      const model = ContourModel(
        id: 'c5',
        title: 'Mandala',
        categories: [ContourCategory.mandala, ContourCategory.patterns],
        svgUrl: 'https://example.com/c5.svg',
        previewUrl: 'https://example.com/c5.png',
      );

      final entity = ContourMapper.toEntity(model);
      expect(entity.categories, [
        ContourCategory.mandala,
        ContourCategory.patterns,
      ]);
      expect(entity.category, ContourCategory.mandala);

      final backToModel = ContourMapper.toModel(entity);
      expect(backToModel.categories, [
        ContourCategory.mandala,
        ContourCategory.patterns,
      ]);
    });
  });
}
