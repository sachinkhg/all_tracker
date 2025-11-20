import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for creating/editing a trip.
class TripFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    String? initialTitle,
    String? initialDestination,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? initialDescription,
    String? tripId,
    required Future<void> Function(
      String title,
      String? destination,
      DateTime? startDate,
      DateTime? endDate,
      String? description,
    ) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Trip',
  }) {
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final destCtrl = TextEditingController(text: initialDestination ?? '');
    final descCtrl = TextEditingController(text: initialDescription ?? '');

    DateTime? startDate = initialStartDate;
    DateTime? endDate = initialEndDate;

    final cs = Theme.of(context).colorScheme;

    String formatDate(DateTime? d) {
      if (d == null) return 'Select date';
      return DateFormat('MMM dd, yyyy').format(d);
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: cs.error,
                      onPressed: () async {
                        await onDelete();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Trip Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          startDate = picked;
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(formatDate(startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: endDate ?? (startDate ?? DateTime.now()),
                          firstDate: startDate ?? DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          endDate = picked;
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(formatDate(endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Title is required')),
                    );
                    return;
                  }
                  await onSubmit(
                    titleCtrl.text.trim(),
                    destCtrl.text.trim().isEmpty ? null : destCtrl.text.trim(),
                    startDate,
                    endDate,
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

