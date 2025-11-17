import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/theme_notifier.dart';
import '../core/design_tokens.dart';
import '../trackers/goal_tracker/features/backup_restore.dart';
import '../trackers/goal_tracker/features/backup/presentation/pages/backup_settings_page.dart';
import 'app_home_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppHomePage()),
                (route) => false,
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.appBar(cs),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
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
          const Divider(height: 32),
          Text('Backup & Restore', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          
          // Local Backup Section (Existing Implementation)
          ExpansionTile(
            title: const Text('Local Backup'),
            subtitle: const Text('Export to .zip file'),
            leading: const Icon(Icons.folder_outlined),
            initiallyExpanded: true,
            children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Backup data'),
                subtitle: const Text('Export all data and preferences to a .zip'),
                onTap: () async {
                  final path = await createBackupZip(context);
                  if (path != null && context.mounted) {
                    // Feedback handled inside helper; provide quick confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup saved to: $path')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('Restore data'),
                subtitle: const Text('Restore from a backup .zip file'),
                onTap: () async {
                  await restoreFromBackupZip(context);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Cloud Backup Section (New Implementation)
          ExpansionTile(
            title: const Text('Cloud Backup'),
            subtitle: const Text('Automatic Google Drive backup'),
            leading: const Icon(Icons.cloud_outlined),
            initiallyExpanded: false,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('Configure Cloud Backup'),
                subtitle: const Text('Set up Google Drive automatic backup'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupSettingsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Cloud Backup'),
                subtitle: const Text('Encrypted backups with E2EE or device key'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cloud Backup'),
                      content: const Text(
                        'Cloud Backup provides automatic encrypted backups to Google Drive.\n\n'
                        'Features:\n'
                        '• AES-256-GCM encryption\n'
                        '• End-to-end encryption (E2EE) with passphrase\n'
                        '• Device key mode for convenience\n'
                        '• Cross-platform restore\n'
                        '• Automatic periodic backups\n\n'
                        'Your data is encrypted before being uploaded to Google Drive.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
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

