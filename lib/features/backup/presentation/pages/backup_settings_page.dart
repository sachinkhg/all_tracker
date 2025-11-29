import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/injection.dart';
import '../../../../../../core/design_tokens.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/backup_state.dart';
import '../widgets/backup_list_item.dart';
import '../widgets/passphrase_dialog.dart';
import '../widgets/backup_name_dialog.dart';
import '../../domain/entities/backup_mode.dart';
import '../../domain/entities/backup_metadata.dart';

class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return BlocProvider(
      create: (_) => createBackupCubit()..checkAuthStatus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Backup'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.appBar(cs),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: cs.onPrimary,
          iconTheme: IconThemeData(
            color: cs.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.black87,
            opacity: 1.0,
          ),
          actionsIconTheme: IconThemeData(
            color: cs.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.black87,
            opacity: 1.0,
          ),
          elevation: 0,
        ),
        body: const _BackupSettingsContent(),
      ),
    );
  }
}

class _BackupSettingsContent extends StatelessWidget {
  const _BackupSettingsContent();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BackupCubit, BackupState>(
      listenWhen: (previous, current) {
        // Only listen to state changes that involve errors or success
        return (current is BackupSignedIn && current.errorMessage != null) ||
            (current is BackupError) ||
            (current is RestoreOperationSuccess) ||
            (current is BackupOperationSuccess);
      },
      listener: (context, state) {
        // Show error messages via SnackBar
        if (state is BackupSignedIn && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (state is BackupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (state is RestoreOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup restored successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is BackupOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup created successfully (${(state.sizeBytes / 1024).toStringAsFixed(1)} KB)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<BackupCubit, BackupState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGoogleSignInSection(context, state),
              const Divider(height: 32),
              _buildBackupSettingsSection(context, state),
              const Divider(height: 32),
              _buildManualBackupSection(context, state),
              const Divider(height: 32),
              _buildBackupListSection(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoogleSignInSection(BuildContext context, BackupState state) {
    final cubit = context.read<BackupCubit>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Google Sign-In',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state is BackupSignedIn)
              // Signed in
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.accountEmail,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => cubit.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              )
            else if (state is BackupSigningIn)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              // Not signed in
              ElevatedButton.icon(
                onPressed: () => cubit.signIn(),
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettingsSection(BuildContext context, BackupState state) {
    final cubit = context.read<BackupCubit>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        BlocBuilder<BackupCubit, BackupState>(
          buildWhen: (prev, curr) => curr is BackupSignedIn,
          builder: (context, state) {
            return SwitchListTile(
              title: const Text('Automatic Backups'),
              subtitle: const Text('Back up your data every 24 hours'),
              value: cubit.autoBackupEnabled,
              onChanged: cubit.setAutoBackupEnabled,
            );
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Encryption Mode'),
          subtitle: const Text('E2EE - Recommended'),
          trailing: BlocBuilder<BackupCubit, BackupState>(
            buildWhen: (prev, curr) => curr is BackupSignedIn,
            builder: (context, state) {
              return DropdownButton<BackupMode>(
                value: cubit.backupMode,
                items: const [
                  DropdownMenuItem(value: BackupMode.e2ee, child: Text('E2EE (Recommended)')),
                  DropdownMenuItem(value: BackupMode.deviceKey, child: Text('Device Key')),
                ],
                onChanged: (mode) {
                  if (mode != null) cubit.setBackupMode(mode);
                },
              );
            },
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('Retention'),
          subtitle: const Text('Keep last N backups'),
          trailing: Text('${cubit.retentionCount}'),
        ),
      ],
    );
  }

  Widget _buildManualBackupSection(BuildContext context, BackupState state) {
    final cubit = context.read<BackupCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Backup',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  state is BackupInProgress ? Icons.backup : Icons.cloud_upload,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: state is BackupSignedIn && state is! BackupInProgress
                      ? () async {
                          // Show backup name dialog
                          final backupName = await showBackupNameDialog(context);
                          if (backupName == null) {
                            // User cancelled
                            return;
                          }
                          
                          // Show passphrase dialog if E2EE
                          final mode = cubit.backupMode;
                          String? passphrase;
                          
                          if (mode == BackupMode.e2ee) {
                            passphrase = await showPassphraseDialog(context, isCreate: true);
                            if (passphrase == null) return;
                          }
                          
                          await cubit.createBackup(
                            mode: mode,
                            passphrase: passphrase,
                            name: backupName.isEmpty ? null : backupName,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Back Up Now'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                if (state is BackupInProgress) ...[
                  const SizedBox(height: 16),
                  Text(state.stage),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: state.progress),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupListSection(BuildContext context, BackupState state) {
    final cubit = context.read<BackupCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restore from Backup',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (state is BackupSignedIn && state.backups.isNotEmpty)
          ...state.backups.map((backup) => BackupListItem(
                backup: backup,
                onRestore: () => _handleRestore(context, cubit, backup),
                onDelete: () => _handleDelete(context, cubit, backup.id),
              ))
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No backups available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleRestore(BuildContext context, BackupCubit cubit, BackupMetadata backup) async {
    final backupDisplayName = backup.name ?? backup.deviceDescription ?? 'backup';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: Text('This will replace all current data with the backup "${backupDisplayName}" from ${backup.createdAt.toString().split(' ').first}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      String? passphrase;
      if (backup.isE2EE) {
        passphrase = await showPassphraseDialog(context, isCreate: false);
        if (passphrase == null) return;
      }
      
      await cubit.restoreBackup(backupId: backup.id, passphrase: passphrase);
    }
  }

  Future<void> _handleDelete(BuildContext context, BackupCubit cubit, String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text('This will permanently delete the backup from Google Drive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.deleteBackup(backupId);
    }
  }
}
