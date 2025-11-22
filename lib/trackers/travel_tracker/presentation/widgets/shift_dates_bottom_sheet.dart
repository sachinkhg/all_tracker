import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for shifting trip dates.
/// Allows user to change start and end dates, with an option to shift itinerary along with dates.
class ShiftDatesBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required DateTime? initialStartDate,
    required DateTime? initialEndDate,
    required Future<void> Function(
      DateTime? startDate,
      DateTime? endDate,
      bool shiftItinerary,
    ) onSubmit,
  }) {
    DateTime? startDate = initialStartDate;
    DateTime? endDate = initialEndDate;
    bool shiftItinerary = false;

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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                  'Shift Dates',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate ?? (endDate ?? DateTime.now()),
                            firstDate: DateTime(2000),
                            lastDate: endDate ?? DateTime(2100),
                          );
                          if (picked != null) {
                            // If end date is set and picked date is after it, show error
                            if (endDate != null) {
                              final pickedNormalized = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                              final endDateNormalized = DateTime(
                                endDate!.year,
                                endDate!.month,
                                endDate!.day,
                              );
                              if (pickedNormalized.isAfter(endDateNormalized)) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Start date cannot be later than end date'),
                                  ),
                                );
                                return;
                              }
                            }
                            setState(() {
                              startDate = picked;
                            });
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
                            // If start date is set and picked date is before it, show error
                            if (startDate != null) {
                              final pickedNormalized = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                              final startDateNormalized = DateTime(
                                startDate!.year,
                                startDate!.month,
                                startDate!.day,
                              );
                              if (pickedNormalized.isBefore(startDateNormalized)) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('End date cannot be earlier than start date'),
                                  ),
                                );
                                return;
                              }
                            }
                            setState(() {
                              endDate = picked;
                            });
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
                const SizedBox(height: 24),
                CheckboxListTile(
                  title: const Text('Shift Itinerary'),
                  subtitle: const Text(
                    'Move all itinerary items along with the dates. Items on days outside the new date range will be lost.',
                  ),
                  value: shiftItinerary,
                  onChanged: (value) {
                    setState(() {
                      shiftItinerary = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    // Validate that start date is not later than end date
                    if (startDate != null && endDate != null) {
                      // Normalize dates to date-only for comparison
                      final startDateNormalized = DateTime(
                        startDate!.year,
                        startDate!.month,
                        startDate!.day,
                      );
                      final endDateNormalized = DateTime(
                        endDate!.year,
                        endDate!.month,
                        endDate!.day,
                      );
                      if (startDateNormalized.isAfter(endDateNormalized)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Start date cannot be later than end date'),
                          ),
                        );
                        return;
                      }
                    }
                    await onSubmit(startDate, endDate, shiftItinerary);
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Shift Dates'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

