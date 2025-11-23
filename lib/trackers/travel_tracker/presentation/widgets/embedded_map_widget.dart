import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/google_places_service.dart';

/// Widget for displaying a location on an embedded Google Map.
/// 
/// Accepts either a location string (which will be geocoded) or direct coordinates.
/// Falls back to external map link if geocoding fails or coordinates are unavailable.
class EmbeddedMapWidget extends StatefulWidget {
  /// Location name/address (will be geocoded to coordinates).
  final String? location;
  
  /// Direct latitude coordinate (if available, location will be ignored).
  final double? latitude;
  
  /// Direct longitude coordinate (if available, location will be ignored).
  final double? longitude;
  
  /// Optional map link to fall back to if map cannot be displayed.
  final String? mapLink;

  const EmbeddedMapWidget({
    super.key,
    this.location,
    this.latitude,
    this.longitude,
    this.mapLink,
  });

  @override
  State<EmbeddedMapWidget> createState() => _EmbeddedMapWidgetState();
}

class _EmbeddedMapWidgetState extends State<EmbeddedMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _coordinates;
  bool _isLoading = true;
  bool _hasError = false;
  final Set<Marker> _markers = {};
  bool _isDisposed = false;

  final GooglePlacesService _placesService = GooglePlacesService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _initializeMap();
      }
    });
  }

  @override
  void didUpdateWidget(EmbeddedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if location or mapLink changed
    if (oldWidget.location != widget.location || 
        oldWidget.mapLink != widget.mapLink ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _isLoading = true;
      _hasError = false;
      _coordinates = null;
      _markers.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          _initializeMap();
        }
      });
    }
  }

  Future<void> _initializeMap() async {
    if (_isDisposed || !mounted) return;
    
    try {
      // If direct coordinates are provided, use them
      if (widget.latitude != null && widget.longitude != null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _coordinates = LatLng(widget.latitude!, widget.longitude!);
            _isLoading = false;
            _hasError = false;
          });
          _createMarker();
        }
        return;
      }

      // If location string is provided, geocode it
      if (widget.location != null && widget.location!.isNotEmpty) {
        try {
          final coords = await _placesService.getCoordinates(widget.location!);
          if (coords != null && mounted && !_isDisposed) {
            setState(() {
              _coordinates = LatLng(coords['lat']!, coords['lng']!);
              _isLoading = false;
              _hasError = false;
            });
            _createMarker();
          } else {
            // Geocoding failed, fall back to external link
            if (mounted && !_isDisposed) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          }
        } catch (e) {
          debugPrint('EmbeddedMapWidget: Error geocoding location: $e');
          if (mounted && !_isDisposed) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        }
      } else {
        // No location or coordinates provided
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('EmbeddedMapWidget: Error initializing map: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _createMarker() {
    if (_coordinates != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('location'),
            position: _coordinates!,
            infoWindow: InfoWindow(
              title: widget.location ?? 'Location',
            ),
          ),
        );
      });
    }
  }

  Future<void> _openExternalMap() async {
    try {
      String? mapLinkToOpen;
      
      // Prefer mapLink if available
      if (widget.mapLink != null && widget.mapLink!.isNotEmpty) {
        mapLinkToOpen = widget.mapLink;
      } else if (widget.location != null && widget.location!.isNotEmpty) {
        // Generate map link from location
        mapLinkToOpen = _placesService.generateMapLink(widget.location!);
      }
      
      if (mapLinkToOpen != null && mapLinkToOpen.isNotEmpty) {
        final uri = Uri.parse(mapLinkToOpen);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('EmbeddedMapWidget: Cannot launch URL: $mapLinkToOpen');
        }
      } else {
        debugPrint('EmbeddedMapWidget: No map link available to open');
      }
    } catch (e) {
      debugPrint('EmbeddedMapWidget: Error opening external map: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing if no location/coordinates/mapLink
    if (widget.location == null && 
        widget.latitude == null && 
        widget.longitude == null && 
        widget.mapLink == null) {
      return const SizedBox.shrink();
    }

    // Show error/fallback if coordinates unavailable
    if (_hasError || (_coordinates == null && !_isLoading)) {
      return Card(
        child: InkWell(
          onTap: _openExternalMap,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                if (widget.location != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.location!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Tap to open map',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading state
    if (_isLoading) {
      return Card(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                if (widget.location != null)
                  Text(
                    widget.location!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Show Google Map
    if (_coordinates != null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              child: Builder(
                builder: (context) {
                  try {
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _coordinates!,
                        zoom: 15.0,
                      ),
                      markers: _markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                      onMapCreated: (GoogleMapController controller) {
                        if (!_isDisposed && mounted) {
                          _mapController = controller;
                        }
                      },
                      onTap: (_) {
                        // Allow tapping on map to open external
                      },
                    );
                  } catch (e) {
                    debugPrint('EmbeddedMapWidget: Error creating GoogleMap: $e');
                    // Return a placeholder that will trigger fallback
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: _openExternalMap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
