import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../domain/entities/traveler.dart';

/// Bottom sheet for creating/editing expenses.
class ExpenseFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String tripId,
    List<Traveler>? travelers,
    DateTime? initialDate,
    ExpenseCategory? initialCategory,
    double? initialAmount,
    String? initialCurrency,
    String? initialDescription,
    String? initialPaidBy,
    required Future<void> Function(
      DateTime date,
      ExpenseCategory category,
      double amount,
      String currency,
      String? description,
      String? paidBy,
    ) onSubmit,
    Future<void> Function()? onDelete,
  }) {
    final amountCtrl = TextEditingController(
      text: initialAmount?.toStringAsFixed(2) ?? '',
    );
    final descCtrl = TextEditingController(text: initialDescription ?? '');

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine if it's edit mode (has initial amount) or create mode
    final bool isEditMode = initialAmount != null;
    final String headerTitle = isEditMode ? 'Edit Expense' : 'Add Expense';

    DateTime selectedDate = initialDate ?? DateTime.now();
    ExpenseCategory? selectedCategory = initialCategory ?? ExpenseCategory.other;
    // Default to traveler marked as self if no initialPaidBy is provided
    String? selectedPaidBy = initialPaidBy;
    if (selectedPaidBy == null && travelers != null && travelers.isNotEmpty) {
      // Find the traveler marked as self (isMainTraveler or relationship == "Self")
      try {
        final selfTraveler = travelers.firstWhere(
          (t) => t.isMainTraveler || (t.relationship?.toLowerCase() == 'self'),
        );
        selectedPaidBy = selfTraveler.id;
      } catch (_) {
        // No self traveler found, keep selectedPaidBy as null
      }
    }

    String formatDate(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

    IconData _getCategoryIcon(ExpenseCategory category) {
      switch (category) {
        case ExpenseCategory.food:
          return Icons.restaurant;
        case ExpenseCategory.travel:
          return Icons.directions_transit;
        case ExpenseCategory.stay:
          return Icons.hotel;
        case ExpenseCategory.other:
          return Icons.category;
      }
    }

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
                            headerTitle,
                            style: textTheme.titleLarge,
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            icon: Icon(Icons.delete, color: cs.error),
                            tooltip: 'Delete Expense',
                            onPressed: () async {
                              Navigator.pop(ctx2);
                              await onDelete();
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

                    // --- Date Selector ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: textTheme.labelLarge),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx2,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDate(selectedDate),
                                  style: textTheme.bodyLarge?.copyWith(color: cs.primary),
                                ),
                                Icon(Icons.calendar_today, size: 20, color: cs.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Category Selector ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: textTheme.labelLarge),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final category = await showModalBottomSheet<ExpenseCategory>(
                              context: ctx2,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Select Category',
                                      style: textTheme.titleMedium,
                                    ),
                                  ),
                                  ...ExpenseCategory.values.map((category) {
                                    return ListTile(
                                      leading: Icon(_getCategoryIcon(category), color: cs.primary),
                                      title: Text(expenseCategoryLabels[category]!),
                                      onTap: () => Navigator.pop(context, category),
                                      selected: selectedCategory == category,
                                    );
                                  }).toList(),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                            if (category != null) {
                              setState(() => selectedCategory = category);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(selectedCategory!),
                                      color: cs.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      expenseCategoryLabels[selectedCategory!]!,
                                      style: textTheme.bodyLarge?.copyWith(color: cs.primary),
                                    ),
                                  ],
                                ),
                                Icon(Icons.arrow_drop_down, size: 24, color: cs.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Amount Field ---
                    TextField(
                      controller: amountCtrl,
                      style: TextStyle(color: cs.primary),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Description Field ---
                    TextField(
                      controller: descCtrl,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    if (travelers != null && travelers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // --- Paid By Selector ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid By (Optional)', style: textTheme.labelLarge),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final travelerId = await showModalBottomSheet<String>(
                                context: ctx2,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Select Who Paid',
                                        style: textTheme.titleMedium,
                                      ),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.person_remove, color: cs.onSurfaceVariant),
                                      title: Text(
                                        'None',
                                        style: TextStyle(
                                          fontWeight: selectedPaidBy == null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      onTap: () => Navigator.pop(context, null),
                                      selected: selectedPaidBy == null,
                                    ),
                                    const Divider(),
                                    ...travelers.map((traveler) {
                                      return ListTile(
                                        leading: Icon(Icons.person, color: cs.primary),
                                        title: Text(
                                          traveler.name,
                                          style: TextStyle(
                                            fontWeight: selectedPaidBy == traveler.id
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: traveler.relationship != null
                                            ? Text(traveler.relationship!)
                                            : null,
                                        onTap: () => Navigator.pop(context, traveler.id),
                                        selected: selectedPaidBy == traveler.id,
                                      );
                                    }).toList(),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                              // Always update state, even if selecting "None" (null)
                              setState(() => selectedPaidBy = travelerId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: cs.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedPaidBy != null
                                            ? travelers
                                                .firstWhere((t) => t.id == selectedPaidBy)
                                                .name
                                            : 'None',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: cs.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_drop_down, size: 24, color: cs.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // --- Action Button ---
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final amount = double.tryParse(amountCtrl.text.trim());
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
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
                            selectedPaidBy,
                          );
                          if (ctx2.mounted) {
                            Navigator.pop(ctx2);
                          }
                        },
                        child: const Text('Save'),
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

