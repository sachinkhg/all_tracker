import 'package:flutter/material.dart';
import '../../domain/entities/file_server_config.dart';

/// Dialog for configuring file server settings (URL, username, password).
class FileServerConfigDialog extends StatefulWidget {
  final FileServerConfig? initialConfig;

  const FileServerConfigDialog({
    super.key,
    this.initialConfig,
  });

  @override
  State<FileServerConfigDialog> createState() =>
      _FileServerConfigDialogState();
}

class _FileServerConfigDialogState extends State<FileServerConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
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
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File Server Configuration'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.0.10/files',
                  helperText: 'For local servers (Android phone), use http:// instead of https://',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveConfig,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveConfig() {
    if (_formKey.currentState!.validate()) {
      final config = FileServerConfig(
        baseUrl: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      Navigator.of(context).pop(config);
    }
  }
}

