import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';

/// Bottom sheet for creating/editing itinerary items.
class ItineraryItemFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String dayId,
    required String tripId,
    ItineraryItemType? initialType,
    String? initialTitle,
    DateTime? initialTime,
    String? initialLocation,
    String? initialNotes,
    String? initialMapLink,
    required Future<void> Function(
      ItineraryItemType type,
      String title,
      DateTime? time,
      String? location,
      String? notes,
      String? mapLink,
    ) onSubmit,
  }) {
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final locationCtrl = TextEditingController(text: initialLocation ?? '');
    final notesCtrl = TextEditingController(text: initialNotes ?? '');
    final mapLinkCtrl = TextEditingController(text: initialMapLink ?? '');

    ItineraryItemType? selectedType = initialType ?? ItineraryItemType.sightseeing;
    DateTime? selectedTime = initialTime;

    String formatTime(DateTime? d) {
      if (d == null) return 'Select time';
      return DateFormat('HH:mm').format(d);
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
              Text(
                'Activity',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<ItineraryItemType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Activity Type',
                  border: OutlineInputBorder(),
                ),
                items: ItineraryItemType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(itineraryItemTypeLabels[type]!),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedType = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime != null
                        ? TimeOfDay.fromDateTime(selectedTime!)
                        : TimeOfDay.now(),
                  );
                  if (time != null) {
                    final now = DateTime.now();
                    selectedTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      time.hour,
                      time.minute,
                    );
                    (ctx as Element).markNeedsBuild();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatTime(selectedTime)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mapLinkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Map Link (URL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
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
                    selectedType!,
                    titleCtrl.text.trim(),
                    selectedTime,
                    locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                    notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    mapLinkCtrl.text.trim().isEmpty ? null : mapLinkCtrl.text.trim(),
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

