import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final amountFormat = NumberFormat('#,##0.00');
    
    final isDebit = expense.amount > 0;
    final amountColor = isDebit ? cs.error : cs.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          child: Icon(
            isDebit ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          expense.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(expense.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Chip(
              label: Text(
                expense.group.displayName,
                style: const TextStyle(fontSize: 11),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: Text(
          amountFormat.format(expense.amount.abs()),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: amountColor,
                // fontWeight: FontWeight.bold,
              ),
        ),
        onTap: onTap,
      ),
    );
  }
}

