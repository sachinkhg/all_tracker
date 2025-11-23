import 'dart:io';
import '../../core/maps_config.dart';

/// Service for managing Google Maps API key configuration.
/// 
/// Reads API key from:
/// 1. Environment variable GOOGLE_MAPS_API_KEY (preferred)
/// 2. Constant in maps_config.dart
/// 3. Returns null if not configured
class MapsConfigService {
  static final MapsConfigService _instance = MapsConfigService._internal();
  factory MapsConfigService() => _instance;
  MapsConfigService._internal();

  /// Gets the Google Maps API key.
  /// 
  /// Priority:
  /// 1. Environment variable GOOGLE_MAPS_API_KEY
  /// 2. Constant from maps_config.dart (googleMapsApiKey)
  /// 3. null if not configured
  String? getApiKey() {
    // First, try environment variable
    final envKey = Platform.environment['GOOGLE_MAPS_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Then try the constant from maps_config.dart
    if (googleMapsApiKey.isNotEmpty) {
      return googleMapsApiKey;
    }
    
    return null;
  }

  /// Checks if API key is configured.
  bool hasApiKey() {
    return getApiKey() != null && getApiKey()!.isNotEmpty;
  }
}

