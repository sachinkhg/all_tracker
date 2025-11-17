import 'package:flutter/material.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/income_entry.dart';
import '../../domain/entities/expense_entry.dart';

/// Bottom sheet for adding/editing income or expense entries
class EntryFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required bool isIncome,
    required List<dynamic> categories,
    IncomeEntry? incomeEntry,
    ExpenseEntry? expenseEntry,
    List<IncomeEntry>? existingIncomeEntries,
    List<ExpenseEntry>? existingExpenseEntries,
    required Future<void> Function(String categoryId, double amount) onSubmit,
    Future<void> Function()? onRemoveEntry,
  }) {
    final isEdit = incomeEntry != null || expenseEntry != null;
    final initialCategoryId = isIncome 
        ? (incomeEntry?.categoryId) 
        : (expenseEntry?.categoryId);
    final initialAmount = isIncome 
        ? (incomeEntry?.amount.toString() ?? '') 
        : (expenseEntry?.amount.toString() ?? '');

    // Create a map of existing entries by category ID for quick lookup
    final Map<String, double> existingAmounts = {};
    if (isIncome && existingIncomeEntries != null) {
      for (final entry in existingIncomeEntries) {
        existingAmounts[entry.categoryId] = entry.amount;
      }
    } else if (!isIncome && existingExpenseEntries != null) {
      for (final entry in existingExpenseEntries) {
        existingAmounts[entry.categoryId] = entry.amount;
      }
    }

    // Create a controller for each category
    final Map<String, TextEditingController> controllers = {};
    for (final category in categories) {
      final categoryId = isIncome 
          ? (category as IncomeCategory).id 
          : (category as ExpenseCategory).id;
      
      String initialValue = '';
      if (isEdit && categoryId == initialCategoryId) {
        // Editing mode: use the entry being edited
        initialValue = initialAmount;
      } else if (existingAmounts.containsKey(categoryId)) {
        // Add mode: pre-fill with existing entry amount if available
        initialValue = existingAmounts[categoryId]!.toString();
      }
      
      controllers[categoryId] = TextEditingController(text: initialValue);
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entryType = isIncome ? 'Income' : 'Expense';

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Header ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit $entryType Entry' : 'Add $entryType Entry',
                            style: textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(ctx2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Category Amount Fields ---
                    ...categories.map((c) {
                      if (isIncome) {
                        final category = c as IncomeCategory;
                        final controller = controllers[category.id]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: controller,
                            style: TextStyle(color: cs.primary),
                            decoration: InputDecoration(
                              labelText: category.name,
                              labelStyle: TextStyle(color: cs.onSurfaceVariant),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        );
                      } else {
                        final category = c as ExpenseCategory;
                        final controller = controllers[category.id]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: controller,
                            style: TextStyle(color: cs.primary),
                            decoration: InputDecoration(
                              labelText: category.name,
                              labelStyle: TextStyle(color: cs.onSurfaceVariant),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        );
                      }
                    }).toList(),
                    const SizedBox(height: 20),

                    // --- Action Button ---
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          // If editing, handle the original entry first
                          if (isEdit && initialCategoryId != null) {
                            final controller = controllers[initialCategoryId]!;
                            final amountText = controller.text.trim();
                            final amount = double.tryParse(amountText);
                            
                            if (amountText.isEmpty || amount == null || amount <= 0) {
                              // Original entry was cleared - remove it
                              if (onRemoveEntry != null) {
                                await onRemoveEntry();
                              }
                            } else {
                              // Original entry still has a value - update it
                              await onSubmit(initialCategoryId, amount);
                            }
                          }
                          
                          // Process all other categories with non-zero amounts (skip the original if editing)
                          for (final category in categories) {
                            final categoryId = isIncome 
                                ? (category as IncomeCategory).id 
                                : (category as ExpenseCategory).id;
                            
                            // Skip the original category if editing (already handled above)
                            if (isEdit && categoryId == initialCategoryId) continue;
                            
                            final controller = controllers[categoryId]!;
                            final amountText = controller.text.trim();
                            
                            if (amountText.isNotEmpty) {
                              final amount = double.tryParse(amountText);
                              if (amount != null && amount > 0) {
                                await onSubmit(categoryId, amount);
                              }
                            }
                          }
                          
                          if (ctx2.mounted) {
                            Navigator.pop(ctx2);
                          }
                        },
                        child: Text(isEdit ? 'Save' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

