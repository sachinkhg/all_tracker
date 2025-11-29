import 'package:flutter/material.dart';

/// Shows a dialog for entering or confirming a passphrase for E2EE backups.
/// 
/// Returns the passphrase entered, or null if cancelled.
Future<String?> showPassphraseDialog(
  BuildContext context, {
  required bool isCreate,
}) async {
  final passphraseController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscureText = true;
  bool confirmObscureText = true;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isCreate ? 'Set Passphrase' : 'Enter Passphrase'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCreate
                        ? 'Create a strong passphrase for end-to-end encryption. You\'ll need this to restore your backup.'
                        : 'Enter your passphrase to restore this encrypted backup.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passphraseController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: 'Passphrase',
                      hintText: 'Enter passphrase...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => obscureText = !obscureText),
                      ),
                    ),
                  ),
                  if (isCreate) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmController,
                      obscureText: confirmObscureText,
                      decoration: InputDecoration(
                        labelText: 'Confirm Passphrase',
                        hintText: 'Re-enter passphrase...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(confirmObscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => confirmObscureText = !confirmObscureText),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Minimum 8 characters required',
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
                  final passphrase = passphraseController.text.trim();
                  if (passphrase.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passphrase must be at least 8 characters')),
                    );
                    return;
                  }
                  
                  if (isCreate) {
                    final confirm = confirmController.text.trim();
                    if (passphrase != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passphrases do not match')),
                      );
                      return;
                    }
                  }
                  
                  Navigator.of(context).pop(passphrase);
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

