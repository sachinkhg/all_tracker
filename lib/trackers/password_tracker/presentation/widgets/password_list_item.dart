import 'package:flutter/material.dart';
import '../../domain/entities/password.dart';

class PasswordListItem extends StatelessWidget {
  final Password password;
  final VoidCallback onTap;

  const PasswordListItem({
    super.key,
    required this.password,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(password.siteName),
        onTap: onTap,
      ),
    );
  }
}

