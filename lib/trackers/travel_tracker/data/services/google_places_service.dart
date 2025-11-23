import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'maps_config_service.dart';
import '../../core/maps_config.dart';

/// Service for interacting with Google Places API.
class GooglePlacesService {
  final String? apiKey;

  GooglePlacesService({String? apiKey}) : apiKey = apiKey ?? MapsConfigService().getApiKey();

  /// Search for a place by query string.
  Future<Map<String, dynamic>?> searchPlace(String query) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return null; // API key not configured
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=$query'
        '&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          return data['results'][0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      // Handle error silently - feature not available without API key
    }

    return null;
  }

  /// Get place details by place ID.
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // Handle error silently
    }

    return null;
  }

  /// Generate a Google Maps URL from a location string.
  /// 
  /// Returns a URL that can be opened in Google Maps or used as a map link.
  /// Format: https://www.google.com/maps/search/?api=1&query=<encoded_location>
  String generateMapLink(String location) {
    if (location.isEmpty) {
      return '';
    }
    
    // URL encode the location string
    final encodedLocation = Uri.encodeComponent(location);
    return '${MapsUrlTemplates.searchUrl}$encodedLocation';
  }

  /// Get autocomplete suggestions for a query string.
  /// 
  /// Returns a list of place predictions with description and place_id.
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String input) async {
    if (apiKey == null || apiKey!.isEmpty || input.trim().isEmpty) {
      debugPrint('GooglePlacesService: API key missing or input empty');
      return [];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$apiKey',
      );

      debugPrint('GooglePlacesService: Fetching autocomplete for: $input');
      final response = await http.get(url);

      debugPrint('GooglePlacesService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data['status'] != null && data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
          debugPrint('GooglePlacesService: API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return [];
        }
        
        if (data['predictions'] != null) {
          final predictions = List<Map<String, dynamic>>.from(data['predictions']);
          debugPrint('GooglePlacesService: Found ${predictions.length} suggestions');
          return predictions;
        }
      } else {
        debugPrint('GooglePlacesService: HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('GooglePlacesService: Exception: $e');
    }

    return [];
  }

  /// Get coordinates (lat, lng) from a location string using geocoding.
  /// 
  /// Returns a Map with 'lat' and 'lng' keys if successful, null otherwise.
  Future<Map<String, double>?> getCoordinates(String location) async {
    final place = await searchPlace(location);
    if (place != null) {
      final geometry = place['geometry'] as Map<String, dynamic>?;
      if (geometry != null) {
        final locationData = geometry['location'] as Map<String, dynamic>?;
        if (locationData != null) {
          return {
            'lat': (locationData['lat'] as num).toDouble(),
            'lng': (locationData['lng'] as num).toDouble(),
          };
        }
      }
    }
    return null;
  }

  /// Get coordinates from a place ID.
  /// 
  /// Returns a Map with 'lat' and 'lng' keys if successful, null otherwise.
  Future<Map<String, double>?> getCoordinatesFromPlaceId(String placeId) async {
    final place = await getPlaceDetails(placeId);
    if (place != null) {
      final geometry = place['geometry'] as Map<String, dynamic>?;
      if (geometry != null) {
        final locationData = geometry['location'] as Map<String, dynamic>?;
        if (locationData != null) {
          return {
            'lat': (locationData['lat'] as num).toDouble(),
            'lng': (locationData['lng'] as num).toDouble(),
          };
        }
      }
    }
    return null;
  }
}

