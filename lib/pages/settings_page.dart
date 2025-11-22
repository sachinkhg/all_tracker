import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/app_theme.dart';
import '../core/theme_notifier.dart';
import '../core/organization_notifier.dart';
import '../core/design_tokens.dart';
import '../features/backup/backup_restore.dart';
import '../features/backup/presentation/pages/backup_settings_page.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/states/auth_state.dart';
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
        iconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: cs.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.95)
              : Colors.black87,
          opacity: 1.0,
        ),
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                final user = authState.user;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'User',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<AuthCubit>().signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 32),
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
          
          const Divider(height: 32),
          Text('Organize', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          
          // Trackers Section
          ExpansionTile(
            title: const Text('Trackers'),
            subtitle: const Text('Show or hide trackers in home page and drawer'),
            leading: const Icon(Icons.track_changes),
            initiallyExpanded: false,
            children: [
              Consumer<OrganizationNotifier>(
                builder: (context, orgNotifier, _) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Goal Tracker'),
                        subtitle: const Text('Track your goals, milestones, tasks, and habits'),
                        value: orgNotifier.goalTrackerEnabled,
                        onChanged: (value) => orgNotifier.setGoalTrackerEnabled(value),
                      ),
                      SwitchListTile(
                        title: const Text('Travel Tracker'),
                        subtitle: const Text('Plan trips, manage itineraries, and journal your travels'),
                        value: orgNotifier.travelTrackerEnabled,
                        onChanged: (value) => orgNotifier.setTravelTrackerEnabled(value),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Utilities Section
          ExpansionTile(
            title: const Text('Utilities'),
            subtitle: const Text('Show or hide utilities in home page and drawer'),
            leading: const Icon(Icons.build),
            initiallyExpanded: false,
            children: [
              Consumer<OrganizationNotifier>(
                builder: (context, orgNotifier, _) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Investment Planner'),
                        subtitle: const Text('Plan your investments based on income and expenses'),
                        value: orgNotifier.investmentPlannerEnabled,
                        onChanged: (value) => orgNotifier.setInvestmentPlannerEnabled(value),
                      ),
                      SwitchListTile(
                        title: const Text('Retirement Planner'),
                        subtitle: const Text('Calculate your retirement corpus and investment needs'),
                        value: orgNotifier.retirementPlannerEnabled,
                        onChanged: (value) => orgNotifier.setRetirementPlannerEnabled(value),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Default Home Page Section
          Consumer<OrganizationNotifier>(
            builder: (context, orgNotifier, _) {
              final enabledOptions = orgNotifier.getEnabledHomePageOptions();
              final currentValue = orgNotifier.defaultHomePage;
              
              // Map home page keys to display names
              String getDisplayName(String key) {
                switch (key) {
                  case 'app_home':
                    return 'App Home Page';
                  case 'goal_tracker':
                    return 'Goal Tracker Home Page';
                  case 'travel_tracker':
                    return 'Travel Tracker Home Page';
                  case 'investment_planner':
                    return 'Investment Planner Home Page';
                  case 'retirement_planner':
                    return 'Retirement Planner Home Page';
                  default:
                    return key;
                }
              }
              
              // Ensure current value is in enabled options, otherwise use app_home
              final selectedValue = enabledOptions.contains(currentValue) 
                  ? currentValue 
                  : 'app_home';
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Home Page',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedValue,
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
                    items: enabledOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          getDisplayName(option),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        orgNotifier.setDefaultHomePage(newValue);
                      }
                    },
                  ),
                ],
              );
            },
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

