import 'package:flutter/material.dart';
import '../../domain/entities/investment_component.dart';

/// Bottom sheet for adding/editing investment components
class ComponentFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    InvestmentComponent? component,
    required Future<void> Function(
      String name,
      double percentage,
      int priority,
      double? minLimit,
      double? maxLimit,
    ) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Add Component',
  }) {
    final nameController = TextEditingController(text: component?.name ?? '');
    final percentageController = TextEditingController(text: component?.percentage.toString() ?? '');
    final priorityController = TextEditingController(text: component?.priority.toString() ?? '');
    final minLimitController = TextEditingController(text: component?.minLimit?.toString() ?? '');
    final maxLimitController = TextEditingController(text: component?.maxLimit?.toString() ?? '');

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                            component == null ? 'Add Component' : 'Edit Component',
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
                                  title: const Text('Delete Component'),
                                  content: const Text('Are you sure you want to delete this component?'),
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
                        labelText: 'Name',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Percentage Field ---
                    TextField(
                      controller: percentageController,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Percentage',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    // --- Priority Field ---
                    TextField(
                      controller: priorityController,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Priority (lower = higher priority)',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // --- Min Limit Field ---
                    TextField(
                      controller: minLimitController,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Min Limit (optional)',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    // --- Max Limit Field ---
                    TextField(
                      controller: maxLimitController,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Max Limit (optional)',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 20),

                    // --- Action Button ---
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final percentageText = percentageController.text.trim();
                          final priorityText = priorityController.text.trim();
                          final minLimitText = minLimitController.text.trim();
                          final maxLimitText = maxLimitController.text.trim();

                          // Validation: name required
                          if (name.isEmpty) return;

                          final percentage = double.tryParse(percentageText) ?? 0.0;
                          final priority = int.tryParse(priorityText) ?? 0;
                          final minLimit = minLimitText.isNotEmpty
                              ? double.tryParse(minLimitText)
                              : null;
                          final maxLimit = maxLimitText.isNotEmpty
                              ? double.tryParse(maxLimitText)
                              : null;

                          await onSubmit(name, percentage, priority, minLimit, maxLimit);

                          // In edit mode, close the form after saving
                          if (component != null) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(ctx2);
                            return;
                          }

                          // In create mode, clear form and keep it open for adding more
                          nameController.clear();
                          percentageController.clear();
                          priorityController.clear();
                          minLimitController.clear();
                          maxLimitController.clear();
                        },
                        child: Text(component == null ? 'Save and Add More' : 'Save'),
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

