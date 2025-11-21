import 'package:flutter/material.dart';

/// Dialog showing backup or restore progress.
class BackupProgressDialog extends StatelessWidget {
  final String stage;
  final double progress;

  const BackupProgressDialog({
    super.key,
    required this.stage,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toStringAsFixed(0);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            stage,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }

  /// Show progress dialog and update it.
  static Future<T?> show<T>(
    BuildContext context,
    Stream<({String stage, double progress})> progressStream,
  ) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<({String stage, double progress})>(
          stream: progressStream,
          initialData: (stage: 'Initializing...', progress: 0.0),
          builder: (context, snapshot) {
            final data = snapshot.data!;
            return BackupProgressDialog(
              stage: data.stage,
              progress: data.progress,
            );
          },
        );
      },
    );
  }
}

