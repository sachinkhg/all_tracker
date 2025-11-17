import 'package:flutter/material.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/expense_category.dart';

/// Bottom sheet for adding/editing categories
class CategoryFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required bool isIncome,
    dynamic category,
    required Future<void> Function(String name) onSubmit,
    Future<void> Function()? onDelete,
  }) {
    final nameController = TextEditingController(
      text: category != null
          ? (isIncome ? (category as IncomeCategory).name : (category as ExpenseCategory).name)
          : '',
    );

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryType = isIncome ? 'Income' : 'Expense';

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
                            category == null
                                ? 'Add $categoryType Category'
                                : 'Edit $categoryType Category',
                            style: textTheme.titleLarge,
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            icon: Icon(Icons.delete, color: cs.error),
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: ctx2,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text('Delete $categoryType Category'),
                                  content: Text('Are you sure you want to delete this category?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldDelete == true) {
                                Navigator.pop(ctx2);
                                await onDelete();
                              }
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(ctx2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Name Field ---
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      autofocus: category == null,
                    ),
                    const SizedBox(height: 20),

                    // --- Action Button ---
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();

                          // Validation: name required
                          if (name.isEmpty) return;

                          await onSubmit(name);

                          // In edit mode, close the form after saving
                          if (category != null) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(ctx2);
                            return;
                          }

                          // In create mode, clear form and keep it open for adding more
                          nameController.clear();
                        },
                        child: Text(category == null ? 'Save and Add More' : 'Save'),
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

