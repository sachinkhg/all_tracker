import 'package:flutter/material.dart';
import '../../domain/entities/file_server_config.dart';
import '../../../../widgets/bottom_sheet_helpers.dart';

/// Bottom sheet for configuring file server settings (URL, username, password).
class FileServerConfigDialog extends StatefulWidget {
  final FileServerConfig? initialConfig;
  final VoidCallback? onDelete;

  const FileServerConfigDialog({
    super.key,
    this.initialConfig,
    this.onDelete,
  });

  /// Shows the file server config bottom sheet and returns the config if saved.
  static Future<FileServerConfig?> show(
    BuildContext context,
    FileServerConfig? initialConfig, {
    VoidCallback? onDelete,
  }) async {
    return await showAppBottomSheet<FileServerConfig>(
      context,
      FileServerConfigDialog(
        initialConfig: initialConfig,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<FileServerConfigDialog> createState() =>
      _FileServerConfigDialogState();
}

class _FileServerConfigDialogState extends State<FileServerConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverNameController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serverNameController = TextEditingController(
      text: widget.initialConfig?.serverName ?? '',
    );
    _urlController = TextEditingController(
      text: widget.initialConfig?.baseUrl ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.initialConfig?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.initialConfig?.password ?? '',
    );
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'File Server Configuration',
                style: textTheme.titleLarge,
              ),
              // Delete button (only show when editing existing config)
              if (widget.initialConfig != null && widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    // Close the config dialog first
                    Navigator.of(context).pop(null);
                    // Wait a frame to ensure the dialog is closed
                    await Future.delayed(const Duration(milliseconds: 100));
                    // Then show the delete dialog
                    widget.onDelete?.call();
                  },
                  tooltip: 'Delete Server',
                  color: cs.error,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Form
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _serverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Server Name',
                      hintText: 'My Server, Home Server, etc.',
                      helperText: 'A friendly name to identify this server',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a server name';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://192.168.0.10/files',
                      helperText: 'For local servers (Android phone), use http:// instead of https://',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a server URL';
                      }
                      final trimmed = value.trim();
                      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      try {
                        final uri = Uri.parse(trimmed);
                        if (uri.host.isEmpty) {
                          return 'Invalid URL: host is required';
                        }
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (Optional)',
                      hintText: 'Leave empty if no authentication required',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password (Optional)',
                      hintText: 'Leave empty if no authentication required',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveConfig(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveConfig,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _saveConfig() {
    if (_formKey.currentState!.validate()) {
      final config = FileServerConfig(
        serverName: _serverNameController.text.trim(),
        baseUrl: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      Navigator.of(context).pop(config);
    }
  }
}

