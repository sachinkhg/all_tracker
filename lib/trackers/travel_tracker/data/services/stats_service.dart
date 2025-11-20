import '../../domain/entities/trip.dart';
import '../../domain/entities/itinerary_item.dart';

/// Service for calculating travel statistics.
class StatsService {
  /// Calculate countries visited from trips.
  static Set<String> getCountriesVisited(List<Trip> trips) {
    final countries = <String>{};
    for (final trip in trips) {
      if (trip.destination != null) {
        // Simple extraction - could be enhanced with proper parsing
        final parts = trip.destination!.split(',').map((s) => s.trim());
        countries.addAll(parts);
      }
    }
    return countries;
  }

  /// Calculate total days traveled.
  static int getTotalDaysTraveled(List<Trip> trips) {
    int totalDays = 0;
    for (final trip in trips) {
      if (trip.startDate != null && trip.endDate != null) {
        final days = trip.endDate!.difference(trip.startDate!).inDays + 1;
        totalDays += days;
      }
    }
    return totalDays;
  }

  /// Calculate approximate distance covered (simplified).
  /// This is a placeholder - would need location data to calculate properly.
  static double getDistanceCovered(List<ItineraryItem> items) {
    // TODO: Implement distance calculation using location coordinates
    // For now, return 0
    return 0.0;
  }
}

