import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/theme_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Color Scheme', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in AppTheme.colorPresets.entries)
                _ColorPresetTile(
                  label: entry.key,
                  color: entry.value,
                  selected: notifier.themeKey == entry.key,
                  onTap: () => notifier.setTheme(entry.key),
                ),
            ],
          ),
          const Divider(height: 32),
          Text('Font', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: notifier.fontKey,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            items: AppTheme.fontPresets.keys.map((String font) {
              return DropdownMenuItem<String>(
                value: font,
                child: Text(
                  font,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                notifier.setFont(newValue);
              }
            },
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: notifier.isDark,
            onChanged: (val) => notifier.toggleDark(val),
          ),
        ],
      ),
    );
  }
}

class _ColorPresetTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorPresetTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 112,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


