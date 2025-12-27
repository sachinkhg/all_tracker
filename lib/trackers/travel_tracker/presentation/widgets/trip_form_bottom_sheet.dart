import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/services/google_places_service.dart';
import 'location_picker_widget.dart';

/// Bottom sheet for creating/editing a trip.
class TripFormBottomSheet {
  static Future<void> show(
    BuildContext context, {
    String? initialTitle,
    TripType? initialTripType,
    String? initialDestination,
    double? initialDestinationLatitude,
    double? initialDestinationLongitude,
    String? initialDestinationMapLink,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? initialDescription,
    String? tripId,
    required Future<void> Function(
      String title,
      TripType? tripType,
      String? destination,
      double? destinationLatitude,
      double? destinationLongitude,
      String? destinationMapLink,
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

    TripType? tripType = initialTripType;
    double? destinationLatitude = initialDestinationLatitude;
    double? destinationLongitude = initialDestinationLongitude;
    String? destinationMapLink = initialDestinationMapLink;
    final placesService = GooglePlacesService();

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
              // Trip Type Selector
              DropdownButtonFormField<TripType>(
                initialValue: tripType,
                decoration: const InputDecoration(
                  labelText: 'Trip Type',
                  border: OutlineInputBorder(),
                ),
                items: TripType.values.map((type) {
                  return DropdownMenuItem<TripType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          tripTypeIcons[type],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(tripTypeLabels[type]!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  tripType = value;
                  (ctx as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 16),
              // Destination with Location Picker
              LocationPickerWidget(
                controller: destCtrl,
                placesService: placesService,
                onLocationSelected: (location) {
                  // Location selected - coordinates will be fetched on submit if needed
                },
                onMapLinkGenerated: (mapLink) {
                  destinationMapLink = mapLink;
                },
              ),
              // Only show date fields when creating a new trip (tripId is null)
              if (tripId == null) ...[
                const SizedBox(height: 16),
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
              ],
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
                  // Only validate dates when creating a new trip (tripId is null)
                  if (tripId == null) {
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
                  }
                  // Fetch coordinates if destination is provided
                  String? finalDestination = destCtrl.text.trim().isEmpty ? null : destCtrl.text.trim();
                  double? finalLatitude = destinationLatitude;
                  double? finalLongitude = destinationLongitude;
                  
                  // If destination is provided but coordinates are not, try to fetch them
                  if (finalDestination != null && finalDestination.isNotEmpty && 
                      (finalLatitude == null || finalLongitude == null)) {
                    try {
                      final coords = await placesService.getCoordinates(finalDestination);
                      if (coords != null) {
                        finalLatitude = coords['lat'];
                        finalLongitude = coords['lng'];
                      }
                    } catch (e) {
                      // If coordinate fetch fails, continue without coordinates
                      debugPrint('Failed to fetch coordinates: $e');
                    }
                  }

                  await onSubmit(
                    titleCtrl.text.trim(),
                    tripType,
                    finalDestination,
                    finalLatitude,
                    finalLongitude,
                    destinationMapLink,
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

