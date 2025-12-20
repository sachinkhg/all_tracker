import 'package:flutter/material.dart';
import '../../domain/entities/password.dart';

class PasswordFormBottomSheet extends StatefulWidget {
  final Password? password;
  final Future<void> Function(
    String siteName,
    String? url,
    String? username,
    String? password,
    bool isGoogleSignIn,
    bool is2FA,
    String? categoryGroup,
    bool hasSecretQuestions,
  ) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const PasswordFormBottomSheet({
    super.key,
    this.password,
    required this.onSubmit,
    this.onDelete,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    Password? password,
    required Future<void> Function(
      String siteName,
      String? url,
      String? username,
      String? password,
      bool isGoogleSignIn,
      bool is2FA,
      String? categoryGroup,
      bool hasSecretQuestions,
    ) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Password',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return PasswordFormBottomSheet(
          password: password,
          onSubmit: onSubmit,
          onDelete: onDelete,
          title: title,
        );
      },
    );
  }

  @override
  State<PasswordFormBottomSheet> createState() => _PasswordFormBottomSheetState();
}

class _PasswordFormBottomSheetState extends State<PasswordFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _siteNameController;
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _categoryController;
  bool _isGoogleSignIn = false;
  bool _is2FA = false;
  bool _hasSecretQuestions = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _siteNameController = TextEditingController(text: widget.password?.siteName ?? '');
    _urlController = TextEditingController(text: widget.password?.url ?? '');
    _usernameController = TextEditingController(text: widget.password?.username ?? '');
    _passwordController = TextEditingController(text: widget.password?.password ?? '');
    _categoryController = TextEditingController(text: widget.password?.categoryGroup ?? '');
    _isGoogleSignIn = widget.password?.isGoogleSignIn ?? false;
    _is2FA = widget.password?.is2FA ?? false;
    _hasSecretQuestions = widget.password?.hasSecretQuestions ?? false;
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await widget.onSubmit(
        _siteNameController.text.trim(),
        _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
        _isGoogleSignIn,
        _is2FA,
        _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        _hasSecretQuestions,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.onDelete!();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _siteNameController,
                  decoration: const InputDecoration(
                    labelText: 'Site Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Site name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category Group (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Google Sign-In'),
                  value: _isGoogleSignIn,
                  onChanged: (value) {
                    setState(() {
                      _isGoogleSignIn = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('2FA Enabled'),
                  value: _is2FA,
                  onChanged: (value) {
                    setState(() {
                      _is2FA = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Has Secret Questions/Other Details'),
                  value: _hasSecretQuestions,
                  onChanged: (value) {
                    setState(() {
                      _hasSecretQuestions = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

