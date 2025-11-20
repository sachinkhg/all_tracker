import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';

/// Bottom sheet for creating/editing expenses.
class ExpenseFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String tripId,
    DateTime? initialDate,
    ExpenseCategory? initialCategory,
    double? initialAmount,
    String? initialCurrency,
    String? initialDescription,
    required Future<void> Function(
      DateTime date,
      ExpenseCategory category,
      double amount,
      String currency,
      String? description,
    ) onSubmit,
  }) {
    final amountCtrl = TextEditingController(
      text: initialAmount?.toStringAsFixed(2) ?? '',
    );
    final descCtrl = TextEditingController(text: initialDescription ?? '');

    DateTime selectedDate = initialDate ?? DateTime.now();
    ExpenseCategory? selectedCategory = initialCategory ?? ExpenseCategory.other;

    String formatDate(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Expense',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (ctx as Element).markNeedsBuild();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatDate(selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(expenseCategoryLabels[category]!),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Valid amount is required')),
                    );
                    return;
                  }
                  await onSubmit(
                    selectedDate,
                    selectedCategory!,
                    amount,
                    defaultCurrency, // Always use default currency
                    descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

