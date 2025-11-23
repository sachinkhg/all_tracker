import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../bloc/itinerary_cubit.dart';
import '../bloc/itinerary_state.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../data/services/google_places_service.dart';
import '../../core/injection.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';

/// Page displaying all itinerary locations on a single map.
class TripMapViewPage extends StatelessWidget {
  final String tripId;

  const TripMapViewPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    // Try to use existing provider from parent, otherwise create new one
    try {
      context.read<ItineraryCubit>();
      // Provider exists, use it
      return TripMapViewPageView(tripId: tripId);
    } catch (_) {
      // No provider exists, create one
      return BlocProvider<ItineraryCubit>(
        create: (_) {
          final cubit = createItineraryCubit();
          cubit.loadItinerary(tripId);
          return cubit;
        },
        child: TripMapViewPageView(tripId: tripId),
      );
    }
  }
}

class TripMapViewPageView extends StatefulWidget {
  final String tripId;

  const TripMapViewPageView({
    super.key,
    required this.tripId,
  });

  @override
  State<TripMapViewPageView> createState() => _TripMapViewPageViewState();
}

class _TripMapViewPageViewState extends State<TripMapViewPageView> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _initialCameraPosition;
  bool _isLoadingMarkers = false;
  final GooglePlacesService _placesService = GooglePlacesService();

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers(
    List<ItineraryDay> days,
    Map<String, List<ItineraryItem>> itemsByDay,
  ) async {
    if (_isLoadingMarkers) return;
    setState(() {
      _isLoadingMarkers = true;
      _markers.clear();
    });

    final List<LatLng> coordinates = [];
    int markerIndex = 0;

    // Process each day's items
    for (final day in days) {
      final items = itemsByDay[day.id] ?? [];
      for (final item in items) {
        // Only process items with locations
        if (item.location == null || item.location!.isEmpty) {
          continue;
        }

        try {
          // Get coordinates for the location
          final coords = await _placesService.getCoordinates(item.location!);
          if (coords != null) {
            final latLng = LatLng(coords['lat']!, coords['lng']!);
            coordinates.add(latLng);

            // Create marker
            final markerId = MarkerId('marker_$markerIndex');
            final dayFormatted = DateFormat('MMM dd').format(day.date);
            final timeFormatted = item.time != null
                ? DateFormat('HH:mm').format(item.time!)
                : '';

            String snippet = 'Day: $dayFormatted';
            if (timeFormatted.isNotEmpty) {
              snippet += '\nTime: $timeFormatted';
            }

            final marker = Marker(
              markerId: markerId,
              position: latLng,
              infoWindow: InfoWindow(
                title: item.title,
                snippet: snippet,
              ),
            );

            setState(() {
              _markers.add(marker);
            });

            markerIndex++;
          }
        } catch (e) {
          // Skip markers that fail to geocode
          debugPrint('Error geocoding location ${item.location}: $e');
        }
      }
    }

    // Set initial camera position to center of all markers
    if (coordinates.isNotEmpty && mounted) {
      double avgLat = 0;
      double avgLng = 0;
      for (final coord in coordinates) {
        avgLat += coord.latitude;
        avgLng += coord.longitude;
      }
      avgLat /= coordinates.length;
      avgLng /= coordinates.length;

      setState(() {
        _initialCameraPosition = LatLng(avgLat, avgLng);
      });

      // Move camera to show all markers
      if (_mapController != null && coordinates.isNotEmpty) {
        double minLat = coordinates.first.latitude;
        double maxLat = coordinates.first.latitude;
        double minLng = coordinates.first.longitude;
        double maxLng = coordinates.first.longitude;
        
        for (final coord in coordinates) {
          if (coord.latitude < minLat) minLat = coord.latitude;
          if (coord.latitude > maxLat) maxLat = coord.latitude;
          if (coord.longitude < minLng) minLng = coord.longitude;
          if (coord.longitude > maxLng) maxLng = coord.longitude;
        }
        
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingMarkers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItineraryCubit>();
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        if (state is ItineraryLoading) {
          return const LoadingView();
        }

        if (state is ItineraryLoaded) {
          final days = state.days;
          final itemsByDay = state.itemsByDay;

          // Extract all items with locations
          final itemsWithLocations = <ItineraryItem>[];
          for (final day in days) {
            final items = itemsByDay[day.id] ?? [];
            itemsWithLocations.addAll(
              items.where((item) =>
                  item.location != null && item.location!.isNotEmpty),
            );
          }

          if (itemsWithLocations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No locations found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add locations to itinerary items to see them on the map',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Load markers if not already loaded
          if (_markers.isEmpty && !_isLoadingMarkers) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMarkers(days, itemsByDay);
            });
          }

          // Default initial position (can be updated when markers load)
          final initialCamera = _initialCameraPosition ??
              const LatLng(0.0, 0.0); // Default to somewhere central

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialCamera,
                  zoom: 10.0,
                ),
                markers: _markers,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // If markers are already loaded, update camera
                  if (_markers.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadMarkers(days, itemsByDay);
                    });
                  }
                },
              ),
              if (_isLoadingMarkers)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading locations...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: cs.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_markers.length} location${_markers.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (state is ItineraryError) {
          return ErrorView(
            message: state.message,
            onRetry: () => cubit.loadItinerary(widget.tripId),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

