import 'package:flutter/material.dart';

class PrimaryElevatedButton extends StatelessWidget {
  final Widget label;
  final IconData? icon;
  final VoidCallback onPressed;

  const PrimaryElevatedButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = icon == null
        ? label
        : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: cs.onPrimary), const SizedBox(width:8), label]);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
      onPressed: onPressed,
      child: child,
    );
  }
}
