import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme_notifier.dart';
import '../core/app_theme.dart';
import '../widgets/shared_dropdown.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Select Theme',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ThemeDropdown(),
          ],
        ),
      ),
    );
  }
}

class ThemeDropdown extends StatelessWidget {
  const ThemeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    final themeNames = AppTheme.themes.keys.toList();
    final currentThemeName = themeNames.firstWhere(
      (key) => AppTheme.themes[key] == themeProvider.currentTheme,
      orElse: () => 'Light',
    );

    return SharedDropdown<String>(
      value: currentThemeName,
      items: themeNames,
      onChanged: (newTheme) {
        if (newTheme != null) {
          themeProvider.setTheme(newTheme);
        }
      },
      itemLabel: (theme) => theme,
    );
  }
}