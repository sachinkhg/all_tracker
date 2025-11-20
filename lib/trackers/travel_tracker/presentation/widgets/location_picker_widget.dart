import 'package:flutter/material.dart';
import '../../data/services/google_places_service.dart';

/// Widget for picking a location with optional Google Places integration.
class LocationPickerWidget extends StatelessWidget {
  final TextEditingController controller;
  final GooglePlacesService? placesService;
  final Function(String)? onLocationSelected;

  const LocationPickerWidget({
    super.key,
    required this.controller,
    this.placesService,
    this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Location',
        border: const OutlineInputBorder(),
        suffixIcon: placesService != null
            ? IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchLocation(context),
                tooltip: 'Search location',
              )
            : null,
      ),
      onChanged: onLocationSelected,
    );
  }

  Future<void> _searchLocation(BuildContext context) async {
    if (placesService == null) return;

    final query = controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a location to search')),
      );
      return;
    }

    final place = await placesService!.searchPlace(query);
    if (place != null && context.mounted) {
      final name = place['name'] as String?;
      final address = place['formatted_address'] as String?;
      if (name != null) {
        controller.text = address ?? name;
        onLocationSelected?.call(controller.text);
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    }
  }
}

