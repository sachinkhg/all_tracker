import 'package:flutter/material.dart';
import '../../domain/entities/expense_group.dart';

class ExpenseGroupFilterChip extends StatelessWidget {
  final ExpenseGroup group;
  final bool isSelected;
  final VoidCallback onTap;

  const ExpenseGroupFilterChip({
    super.key,
    required this.group,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return FilterChip(
      label: Text(group.displayName),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

