import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('load returns an empty list before any color was saved', () async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final RecentColorsServiceImpl service = RecentColorsServiceImpl(
      preferences: preferences,
    );

    expect(await service.load(), isEmpty);
  });

  test('remember persists colors in order and deduplicates them', () async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final RecentColorsServiceImpl service = RecentColorsServiceImpl(
      preferences: preferences,
    );

    await service.remember('#FF0000');
    await service.remember('#00FF00');
    await service.remember('#FF0000');

    expect(
      preferences.getStringList(RecentColorsServiceImpl.storageKey),
      <String>['#FF0000', '#00FF00'],
    );
    expect(await service.load(), <String>['#FF0000', '#00FF00']);
  });

  test('load drops malformed stored values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      RecentColorsServiceImpl.storageKey: <String>['bad', '#FFFFFF', '#FFFFFF'],
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final RecentColorsServiceImpl service = RecentColorsServiceImpl(
      preferences: preferences,
    );

    expect(await service.load(), <String>['#FFFFFF']);
  });
}
