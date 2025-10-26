import 'package:hive_flutter/hive_flutter.dart';
import '../goal_tracker/core/constants.dart';
import '../goal_tracker/core/box_provider.dart';
const String _kThemeKey = 'theme_key';
const String _kFontKey = 'font_key';
const String _kIsDark = 'is_dark';

class ThemePreferencesService {
  final BoxProvider boxes;

  ThemePreferencesService({BoxProvider? boxes}) : boxes = boxes ?? HiveBoxProvider();

  Future<void> init() async {
    if (!boxes.isBoxOpen(themePreferencesBoxName)) {
      await boxes.openBox(themePreferencesBoxName);
    }
  }

  Box<dynamic> get _box => boxes.box(themePreferencesBoxName);

  String? loadThemeKey() => _box.get(_kThemeKey) as String?;
  String? loadFontKey() => _box.get(_kFontKey) as String?;
  bool loadIsDark() => (_box.get(_kIsDark) as bool?) ?? false;

  Future<void> saveThemeKey(String key) async => _box.put(_kThemeKey, key);
  Future<void> saveFontKey(String key) async => _box.put(_kFontKey, key);
  Future<void> saveIsDark(bool isDark) async => _box.put(_kIsDark, isDark);
}


