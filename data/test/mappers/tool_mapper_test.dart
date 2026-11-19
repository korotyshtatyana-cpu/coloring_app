import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolMapper', () {
    test('maps the soft tool identifiers to soft brush types', () {
      expect(ToolMapper.brushTypeForId('soft_liner'), BrushType.softLiner);
      expect(
        ToolMapper.brushTypeForId('soft_round_basic'),
        BrushType.softRoundBasic,
      );
    });

    test('keeps standard tools hard-edged', () {
      expect(ToolMapper.brushTypeForId('round_basic'), BrushType.circle);
      expect(ToolMapper.brushTypeForId('fine_liner'), BrushType.circle);
      expect(ToolMapper.brushTypeForId('watercolor'), BrushType.watercolor);
      expect(ToolMapper.brushTypeForId('unknown_tool'), BrushType.circle);
    });

    test('reads snake_case and camelCase remote rows', () {
      final ToolEntity? snake = ToolMapper.fromRemoteRow(<String, dynamic>{
        'id': 'soft_liner',
        'name_key': 'brush_soft_liner',
        'preview_path': 'previews/soft_liner.png',
        'is_pressure_sensitive': true,
      });
      final ToolEntity? camel = ToolMapper.fromRemoteRow(<String, dynamic>{
        'id': 'soft_round_basic',
        'nameKey': 'brush_soft_round_basic',
        'previewPath': 'previews/soft_round_basic.png',
        'isPressureSensitive': false,
      });

      expect(snake, isNotNull);
      expect(snake!.nameKey, 'brush_soft_liner');
      expect(snake.isPressureSensitive, isTrue);
      expect(snake.brushType, BrushType.softLiner);
      expect(camel, isNotNull);
      expect(camel!.isPressureSensitive, isFalse);
      expect(camel.brushType, BrushType.softRoundBasic);
    });

    test('keeps the canonical pressure flag for built-in brushes', () {
      final ToolEntity? soft = ToolMapper.fromRemoteRow(<String, dynamic>{
        'id': 'soft_liner',
        'name_key': 'brush_soft_liner',
        // A stale cache row or a partially filled remote row must not turn
        // pressure support off for a built-in brush.
        'is_pressure_sensitive': false,
      });
      final ToolEntity? basic = ToolMapper.fromRemoteRow(<String, dynamic>{
        'id': 'round_basic',
        'name_key': 'brush_round_basic',
        'is_pressure_sensitive': true,
      });

      expect(soft!.isPressureSensitive, isTrue);
      expect(basic!.isPressureSensitive, isFalse);
    });

    test('trusts the catalog flag for brushes unknown to this build', () {
      final ToolEntity? tool = ToolMapper.fromRemoteRow(<String, dynamic>{
        'id': 'future_brush',
        'name_key': 'brush_future',
        'is_pressure_sensitive': true,
      });

      expect(tool!.isPressureSensitive, isTrue);
      expect(tool.brushType, BrushType.circle);
    });
  });
}
