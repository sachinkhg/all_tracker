import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/drive_backup_cubit.dart';
import '../states/drive_backup_state.dart';
import '../../../../core/design_tokens.dart';
import '../../core/injection.dart';

/// Settings page for Drive backup feature.
class DriveBackupSettingsPage extends StatelessWidget {
  const DriveBackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createDriveBackupCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drive Backup'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.appBar(Theme.of(context).colorScheme),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
        ),
        body: const _DriveBackupSettingsContent(),
      ),
    );
  }
}

class _DriveBackupSettingsContent extends StatefulWidget {
  const _DriveBackupSettingsContent();

  @override
  State<_DriveBackupSettingsContent> createState() => _DriveBackupSettingsContentState();
}

class _DriveBackupSettingsContentState extends State<_DriveBackupSettingsContent> {
  final _folderIdController = TextEditingController();

  @override
  void dispose() {
    _folderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriveBackupCubit, DriveBackupState>(
      listener: (context, state) {
        if (state is DriveBackupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is DriveBackupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: BlocBuilder<DriveBackupCubit, DriveBackupState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSetupSection(context, state),
              const Divider(height: 32),
              _buildBackupSection(context, state),
              const Divider(height: 32),
              _buildSyncActionsSection(context, state),
              const Divider(height: 32),
              _buildStatusSection(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSetupSection(BuildContext context, DriveBackupState state) {
    final cubit = context.read<DriveBackupCubit>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Drive Backup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _folderIdController,
              decoration: const InputDecoration(
                labelText: 'Google Drive Folder ID or URL',
                hintText: 'Paste folder ID or URL here',
                border: OutlineInputBorder(),
                helperText: 'Get the folder ID from the Google Drive URL',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: state is DriveBackupLoading
                  ? null
                  : () async {
                      final folderId = _folderIdController.text.trim();
                      if (folderId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a folder ID or URL'),
                          ),
                        );
                        return;
                      }
                      await cubit.setupBackup(folderId);
                    },
              icon: const Icon(Icons.settings),
              label: const Text('Setup Backup'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context, DriveBackupState state) {
    final cubit = context.read<DriveBackupCubit>();
    final isConfigured = state is DriveBackupConfigured || state is DriveBackupIdle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup to Drive',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Backs up all book data to Google Drive and syncs CRUD operations to Google Sheets.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (isConfigured && state is! DriveBackupLoading)
                  ? () => cubit.backupToDrive()
                  : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Backup Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (state is DriveBackupLoading && state.operation == 'backup') ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(state.message),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildSyncActionsSection(BuildContext context, DriveBackupState state) {
    final cubit = context.read<DriveBackupCubit>();
    final isConfigured = state is DriveBackupConfigured || state is DriveBackupIdle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Actions from Sheet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Processes actions marked in the Google Sheet. '
              'Mark rows with actions in the Action column, then sync to apply changes to the app.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Book Actions:\n'
              '• CREATE BOOK - Create a new book and associated read\n'
              '• UPDATE BOOK - Update book metadata (title, author, etc.)\n'
              '• DELETE BOOK - Delete book and all read history\n\n'
              'Read History Actions:\n'
              '• CREATE REREAD - Add new read history entry to existing book\n'
              '• UPDATE REREAD - Update an existing read history entry (matches by dateStarted)\n'
              '• DELETE REREAD - Delete a specific read history entry (matches by dateStarted)',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (isConfigured && state is! DriveBackupLoading)
                  ? () => cubit.syncActionsFromSheet()
                  : null,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Actions Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (state is DriveBackupLoading && state.operation == 'sync') ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(state.message),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, DriveBackupState state) {
    if (state is DriveBackupConfigured) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildStatusRow('Folder ID', state.config.folderId),
              _buildStatusRow('Spreadsheet ID', state.config.spreadsheetId),
              if (state.config.lastBackupTime != null)
                _buildStatusRow(
                  'Last Backup',
                  _formatDateTime(state.config.lastBackupTime!),
                ),
              if (state.config.lastRestoreTime != null)
                _buildStatusRow(
                  'Last Restore',
                  _formatDateTime(state.config.lastRestoreTime!),
                ),
              if (state.config.lastSheetSyncTime != null)
                _buildStatusRow(
                  'Last Sheet Sync',
                  _formatDateTime(state.config.lastSheetSyncTime!),
                ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

