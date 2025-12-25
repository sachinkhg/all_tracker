import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_tokens.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/backup_state.dart';
import '../../core/injection.dart';
import '../../domain/entities/backup_metadata.dart';
import 'backup_list_item.dart';
import 'passphrase_dialog.dart';

/// Bottom sheet for syncing/restoring from available backups.
/// Shows a list of all backups and allows the user to select one to restore.
class BackupSyncBottomSheet extends StatefulWidget {
  const BackupSyncBottomSheet({super.key});

  @override
  State<BackupSyncBottomSheet> createState() => _BackupSyncBottomSheetState();
}

class _BackupSyncBottomSheetState extends State<BackupSyncBottomSheet> {
  BackupCubit? _cubit;

  @override
  void initState() {
    super.initState();
    // Initialize cubit and check auth, load backups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cubit != null) {
        _cubit!.checkAuthStatus();
        _cubit!.loadBackups();
      }
    });
  }

  Future<void> _handleRestore(BackupMetadata backup) async {
    if (_cubit == null) return;

    // Show passphrase dialog if E2EE
    String? passphrase;
    if (backup.isE2EE) {
      passphrase = await showPassphraseDialog(context, isCreate: false);
      if (passphrase == null) return; // User cancelled
    }

    // Restore the backup
    await _cubit!.restoreBackup(backupId: backup.id, passphrase: passphrase);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) {
        final cubit = createBackupCubit();
        _cubit = cubit;
        return cubit;
      },
      child: BlocListener<BackupCubit, BackupState>(
        listener: (context, state) {
          if (state is RestoreOperationSuccess) {
            Navigator.of(context).pop(true); // Return true to indicate success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup restored successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is BackupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppGradients.appBar(cs),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync,
                          color: cs.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sync from Backup',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: cs.brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: cs.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.95)
                                : Colors.black87,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: BlocBuilder<BackupCubit, BackupState>(
                    builder: (context, state) {
                      if (state is BackupSigningIn) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Signing in...'),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is BackupSignedOut) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 64,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sign in to Google Drive',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You need to sign in to Google Drive to view and restore backups.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<BackupCubit>().signIn();
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Sign In'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is RestoreInProgress) {
                        return Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                state.stage,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: state.progress > 0 ? state.progress : null,
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is BackupSignedIn) {
                        final backups = state.backups;

                        if (backups.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.backup_outlined,
                                  size: 64,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No backups found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a backup first to restore from it.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Account info and refresh button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Signed in as: ${state.accountEmail}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () {
                                      context.read<BackupCubit>().loadBackups();
                                    },
                                    tooltip: 'Refresh',
                                  ),
                                ],
                              ),
                            ),

                            // Backup list
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: backups.length,
                                itemBuilder: (context, index) {
                                  final backup = backups[index];
                                  return BackupListItem(
                                    backup: backup,
                                    onRestore: () => _handleRestore(backup),
                                    onDelete: () {
                                      // Show delete confirmation
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Backup'),
                                          content: Text(
                                            'Are you sure you want to delete this backup?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                context.read<BackupCubit>().deleteBackup(backup.id);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: cs.error,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      // Default: show loading
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shows the backup sync bottom sheet.
/// Returns true if a backup was successfully restored, false otherwise.
Future<bool?> showBackupSyncDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const BackupSyncBottomSheet(),
  );
}

