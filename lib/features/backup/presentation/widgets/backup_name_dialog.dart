import 'package:flutter/material.dart';

/// Shows a dialog for entering a name for the backup.
/// 
/// Returns the name entered, or null if cancelled.
Future<String?> showBackupNameDialog(BuildContext context) async {
  final nameController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Name Your Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Give your backup a name to easily identify it later.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Backup Name',
                  hintText: 'e.g., Before major update, Weekly backup...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              Text(
                'Optional: Leave empty to use default name',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              Navigator.of(context).pop(name.isEmpty ? null : name);
            },
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
}

