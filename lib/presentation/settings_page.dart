import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme_notifier.dart';
import '../core/app_theme.dart';
import '../widgets/shared_dropdown.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    // You can listen to ThemeNotifier here if you want reactive updates
    Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

class ThemeDropdown extends StatefulWidget {
  const ThemeDropdown({super.key});

  @override
  State<ThemeDropdown> createState() => _ThemeDropdownState();
}

class _ThemeDropdownState extends State<ThemeDropdown> {
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
