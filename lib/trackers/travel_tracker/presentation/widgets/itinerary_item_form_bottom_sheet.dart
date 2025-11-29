import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/services/google_places_service.dart';
import 'location_picker_widget.dart';

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
    Future<void> Function()? onDelete,
  }) {
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final locationCtrl = TextEditingController(text: initialLocation ?? '');
    final notesCtrl = TextEditingController(text: initialNotes ?? '');
    // Store map link internally (not shown to user)
    String? currentMapLink = initialMapLink;

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine if it's edit mode (has initial title) or create mode
    final bool isEditMode = initialTitle != null && initialTitle.isNotEmpty;
    final String headerTitle = isEditMode ? 'Edit Activity' : 'Add Activity';

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
                            tooltip: 'Delete Activity',
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

                    // --- Activity Type Selector ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activity Type', style: textTheme.labelLarge),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final type = await showModalBottomSheet<ItineraryItemType>(
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
                                      'Select Activity Type',
                                      style: textTheme.titleMedium,
                                    ),
                                  ),
                                  ...ItineraryItemType.values.map((type) {
                                    return ListTile(
                                      leading: Icon(itineraryItemTypeIcons[type], color: cs.primary),
                                      title: Text(itineraryItemTypeLabels[type]!),
                                      onTap: () => Navigator.pop(context, type),
                                      selected: selectedType == type,
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                            if (type != null) {
                              setState(() => selectedType = type);
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
                                    if (selectedType != null)
                                      Icon(
                                        itineraryItemTypeIcons[selectedType!],
                                        color: cs.primary,
                                        size: 20,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedType != null
                                          ? itineraryItemTypeLabels[selectedType!]!
                                          : 'Select activity type',
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

                    // --- Title Field ---
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Time Selector ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time', style: textTheme.labelLarge),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: ctx2,
                              initialTime: selectedTime != null
                                  ? TimeOfDay.fromDateTime(selectedTime!)
                                  : TimeOfDay.now(),
                            );
                            if (time != null) {
                              final now = DateTime.now();
                              setState(() {
                                selectedTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
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
                                  formatTime(selectedTime),
                                  style: textTheme.bodyLarge?.copyWith(color: cs.primary),
                                ),
                                Row(
                                  children: [
                                    if (selectedTime != null)
                                      IconButton(
                                        icon: Icon(Icons.clear, size: 20, color: cs.onSurfaceVariant),
                                        onPressed: () => setState(() => selectedTime = null),
                                      ),
                                    Icon(Icons.access_time, size: 20, color: cs.onSurfaceVariant),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Location Field with Google Places Integration ---
                    LocationPickerWidget(
                      controller: locationCtrl,
                      placesService: GooglePlacesService(), // Uses MapsConfigService for API key
                      onLocationSelected: (location) {
                        // Location selected callback - this is called when user types
                        // Map link will be generated on submit if not already set
                      },
                      onMapLinkGenerated: (mapLink) {
                        // Store map link when generated from autocomplete selection
                        // This uses the full description for accurate location
                        currentMapLink = mapLink;
                      },
                    ),
                    const SizedBox(height: 12),

                    // --- Notes Field ---
                    TextField(
                      controller: notesCtrl,
                      style: TextStyle(color: cs.primary),
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // --- Action Button ---
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(content: Text('Title is required')),
                            );
                            return;
                          }
                          // Generate map link if location exists but map link is missing
                          String? finalMapLink = currentMapLink;
                          if (finalMapLink == null || finalMapLink.isEmpty) {
                            final location = locationCtrl.text.trim();
                            if (location.isNotEmpty) {
                              final placesService = GooglePlacesService();
                              finalMapLink = placesService.generateMapLink(location);
                            }
                          }
                          
                          await onSubmit(
                            selectedType!,
                            title,
                            selectedTime,
                            locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                            notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            finalMapLink?.isEmpty ?? true ? null : finalMapLink,
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

