/// Constants and configuration for Google Maps integration in Travel Tracker.
/// 
/// Note: API keys should be configured in platform-specific files:
/// - iOS: Info.plist (GMSApiKey)
/// - Android: AndroidManifest.xml (com.google.android.geo.API_KEY)
/// 
/// For Places API calls, you can set the API key here or use MapsConfigService.

/// Google Maps API Key
/// 
/// IMPORTANT: Replace this with your actual Google Maps API key.
/// You can get it from: https://console.cloud.google.com/google/maps-apis/credentials
/// 
/// Alternatively, set the GOOGLE_MAPS_API_KEY environment variable.
/// 
/// The key from Info.plist (iOS) or strings.xml (Android) is used for native maps,
/// but for Places API HTTP calls, we need it here or via environment variable.
const String googleMapsApiKey = 'AIzaSyCFkbnA9iZjG3W_wNnoCRUMrmBuKl5VmNk';

/// Google Maps URL templates for generating map links.
class MapsUrlTemplates {
  /// Template for Google Maps search URL.
  /// Use with: https://www.google.com/maps/search/?api=1&query=<encoded_location>
  static const String searchUrl = 'https://www.google.com/maps/search/?api=1&query=';

  /// Template for Google Maps directions URL.
  /// Use with: https://www.google.com/maps/dir/?api=1&destination=<encoded_location>
  static const String directionsUrl = 'https://www.google.com/maps/dir/?api=1&destination=';

  /// Template for Google Maps place details URL.
  /// Use with: https://www.google.com/maps/place/?q=<encoded_location>
  static const String placeUrl = 'https://www.google.com/maps/place/?q=';
}

