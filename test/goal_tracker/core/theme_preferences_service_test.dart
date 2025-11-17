import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/core/theme_preferences_service.dart';
import 'package:all_tracker/trackers/goal_tracker/core/box_provider.dart';
import '../../helpers/fake_hive_box.dart';
import 'package:hive/hive.dart';

class TestBoxProvider implements BoxProvider {
  final Map<String, FakeBox<dynamic>> _boxes = {};

  @override
  Box<T> box<T>(String name) {
    final existing = _boxes[name];
    if (existing != null) return existing as Box<T>;
    final created = FakeBox<T>(name);
    _boxes[name] = created as FakeBox<dynamic>;
    return created as Box<T>;
  }

  @override
  bool isBoxOpen(String name) => true;

  @override
  Future<Box<T>> openBox<T>(String name) async => box<T>(name);
}

void main() {
  test('ThemePreferencesService saves and loads values using BoxProvider', () async {
    final boxes = TestBoxProvider();
    final svc = ThemePreferencesService(boxes: boxes);

    await svc.init();
    expect(svc.loadThemeKey(), isNull);
    expect(svc.loadFontKey(), isNull);
    expect(svc.loadIsDark(), false);

    await svc.saveThemeKey('Blue');
    await svc.saveFontKey('Roboto');
    await svc.saveIsDark(true);

    expect(svc.loadThemeKey(), 'Blue');
    expect(svc.loadFontKey(), 'Roboto');
    expect(svc.loadIsDark(), true);
  });
}


