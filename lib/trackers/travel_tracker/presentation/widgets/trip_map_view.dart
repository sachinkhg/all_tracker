import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/trip.dart';

/// Map view widget for trip display.
///
/// This widget displays trips on a Google Map with markers
/// for each trip that has location coordinates.
class TripMapView extends StatefulWidget {
  final List<Trip> trips;
  final Function(BuildContext, Trip) onTap;
  final Map<String, bool>? visibleFields;
  final bool filterActive;

  const TripMapView({
    super.key,
    required this.trips,
    required this.onTap,
    this.visibleFields,
    this.filterActive = false,
  });

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _initialCameraPosition;
  bool _isLoadingMarkers = false;
  Trip? _selectedTrip;
  bool _hasMapError = false;
  String? _mapErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarkers();
    });
  }

  @override
  void didUpdateWidget(TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload markers if trips changed
    if (oldWidget.trips != widget.trips) {
      _loadMarkers();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _loadMarkers() {
    if (_isLoadingMarkers || !mounted) return;
    
    setState(() {
      _isLoadingMarkers = true;
      _markers.clear();
    });

    // Use a local set to build markers, then update state once
    final Set<Marker> newMarkers = {};
    final List<LatLng> coordinates = [];

    // Process trips with location coordinates
    for (final trip in widget.trips) {
      // Only process trips with coordinates
      if (trip.destinationLatitude == null || trip.destinationLongitude == null) {
        continue;
      }

      final latLng = LatLng(trip.destinationLatitude!, trip.destinationLongitude!);
      coordinates.add(latLng);

      // Create marker
      final markerId = MarkerId('trip_${trip.id}');
      
      String snippet = trip.destination ?? 'Trip destination';
      if (trip.startDate != null) {
        final dateFormatted = DateFormat('MMM dd, yyyy').format(trip.startDate!);
        snippet += '\nStart: $dateFormatted';
      }

      final marker = Marker(
        markerId: markerId,
        position: latLng,
        infoWindow: InfoWindow(
          title: trip.title,
          snippet: snippet,
        ),
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedTrip = trip;
            });
          }
        },
      );

      newMarkers.add(marker);
    }

    // Update state once with all markers
    if (!mounted) return;
    
    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });

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
      if (_mapController != null && mounted && coordinates.length > 1) {
        try {
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

          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          ).catchError((error) {
            debugPrint('Error animating camera to bounds: $error');
          });
        } catch (e) {
          debugPrint('Error calculating bounds: $e');
        }
      } else if (_mapController != null && mounted && coordinates.length == 1) {
        // Single marker - center on it with reasonable zoom
        try {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(coordinates.first, 12.0),
          ).catchError((error) {
            debugPrint('Error animating camera to single marker: $error');
          });
        } catch (e) {
          debugPrint('Error animating camera: $e');
        }
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
    final theme = Theme.of(context);
    final tripsWithLocations = widget.trips.where((trip) =>
        trip.destinationLatitude != null && trip.destinationLongitude != null).toList();

    if (tripsWithLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No trips with locations',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add destination coordinates to trips to see them on the map',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Default initial position (can be updated when markers load)
    final initialCamera = _initialCameraPosition ??
        (tripsWithLocations.isNotEmpty &&
                tripsWithLocations.first.destinationLatitude != null &&
                tripsWithLocations.first.destinationLongitude != null
            ? LatLng(
                tripsWithLocations.first.destinationLatitude!,
                tripsWithLocations.first.destinationLongitude!,
              )
            : const LatLng(0.0, 0.0));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have valid constraints
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_hasMapError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load map',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_mapErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _mapErrorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasMapError = false;
                      _mapErrorMessage = null;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Builder(
                builder: (context) {
                  try {
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialCamera,
                        zoom: 10.0,
                      ),
                      markers: _markers,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapType: MapType.normal,
                      onMapCreated: (GoogleMapController controller) {
                        if (mounted) {
                          setState(() {
                            _mapController = controller;
                          });
                          // If markers are already loaded, update camera
                          if (_markers.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _loadMarkers();
                              }
                            });
                          }
                        }
                      },
                    );
                  } catch (e, stackTrace) {
                    debugPrint('TripMapView: Error creating GoogleMap: $e');
                    debugPrint('TripMapView: Stack trace: $stackTrace');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _hasMapError = true;
                          _mapErrorMessage = 'Failed to initialize map: ${e.toString()}';
                        });
                      }
                    });
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Map unavailable',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your Google Maps configuration',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
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
                          style: theme.textTheme.bodyMedium,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              if (_selectedTrip != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedTrip!.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedTrip = null;
                                });
                              },
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        if (_selectedTrip!.destination != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedTrip!.destination!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onTap(context, _selectedTrip!);
                            },
                            child: const Text('View Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_markers.length} trip${_markers.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

