import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/google_places_service.dart';

/// Widget for picking a location with Google Places autocomplete suggestions.
class LocationPickerWidget extends StatefulWidget {
  final TextEditingController controller;
  final GooglePlacesService? placesService;
  final Function(String)? onLocationSelected;
  /// Callback called when a map link is auto-generated.
  /// Parameter is the generated Google Maps URL.
  final Function(String)? onMapLinkGenerated;

  const LocationPickerWidget({
    super.key,
    required this.controller,
    this.placesService,
    this.onLocationSelected,
    this.onMapLinkGenerated,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.controller.text.isNotEmpty) {
        _fetchSuggestions(widget.controller.text);
      }
    } else {
      // Delay removal to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    
    // Don't auto-generate map link on every text change
    // Only generate when a suggestion is selected (handled in _selectSuggestion)
    // This prevents generating incorrect map links from partial text

    // Debounce autocomplete requests
    if (widget.placesService == null) {
      _removeOverlay();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (text.trim().isNotEmpty && _focusNode.hasFocus) {
        _fetchSuggestions(text);
      } else {
        _removeOverlay();
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    debugPrint('LocationPickerWidget: _fetchSuggestions called with: "$query"');
    
    if (widget.placesService == null || query.trim().isEmpty) {
      debugPrint('LocationPickerWidget: PlacesService is null or query is empty');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
          _showSuggestions = false;
        });
        _removeOverlay();
      }
      return;
    }

    // Check if query still matches current text
    final currentText = widget.controller.text.trim();
    if (query != currentText) {
      debugPrint('LocationPickerWidget: Query is stale. Query: "$query", Current: "$currentText"');
      return; // Query is stale
    }

    debugPrint('LocationPickerWidget: Starting to fetch suggestions...');
    if (mounted) {
      setState(() {
        _isLoading = true;
        _suggestions = [];
        _showSuggestions = true;
      });
      _updateOverlay();
    }

    try {
      final suggestions = await widget.placesService!.getAutocompleteSuggestions(query);
      debugPrint('LocationPickerWidget: Received ${suggestions.length} suggestions');
      
      // Double-check query is still current
      if (mounted && query == widget.controller.text.trim() && _focusNode.hasFocus) {
        debugPrint('LocationPickerWidget: Updating UI with suggestions');
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          _showSuggestions = suggestions.isNotEmpty;
        });
        _updateOverlay();
      } else {
        debugPrint('LocationPickerWidget: Not updating - query changed or lost focus');
      }
    } catch (e) {
      debugPrint('LocationPickerWidget: Error fetching suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
          _showSuggestions = false;
        });
        _removeOverlay();
      }
    }
  }

  void _updateOverlay() {
    debugPrint('LocationPickerWidget: _updateOverlay - hasFocus: ${_focusNode.hasFocus}, isLoading: $_isLoading, suggestions: ${_suggestions.length}, showSuggestions: $_showSuggestions');
    
    if (!_focusNode.hasFocus) {
      debugPrint('LocationPickerWidget: No focus, removing overlay');
      _removeOverlay();
      return;
    }

    // Remove existing overlay
    _removeOverlay();

    // Only show overlay if we have suggestions or are loading
    if (!_showSuggestions || (!_isLoading && _suggestions.isEmpty)) {
      debugPrint('LocationPickerWidget: Not showing overlay - showSuggestions: $_showSuggestions, isLoading: $_isLoading, suggestions: ${_suggestions.length}');
      return;
    }

    debugPrint('LocationPickerWidget: Creating and inserting overlay');
    // Create new overlay
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final renderBox = this.context.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) {
          return const SizedBox.shrink();
        }

        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);

        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4.0,
          width: size.width,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No suggestions found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            final description = suggestion['description'] as String? ?? '';
                            final placeId = suggestion['place_id'] as String?;
                            // Extract place name from structured_formatting if available
                            final structuredFormatting = suggestion['structured_formatting'] as Map<String, dynamic>?;
                            final placeName = structuredFormatting?['main_text'] as String? ?? 
                                             description.split(',').first.trim();

                            return InkWell(
                              onTap: () => _selectSuggestion(placeName, description, placeId),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        description,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectSuggestion(String placeName, String fullDescription, String? placeId) async {
    _removeOverlay();
    _focusNode.unfocus();

    // Use only the place name (not full address) for display
    widget.controller.text = placeName;
    widget.onLocationSelected?.call(placeName);

    // Generate map link using the full description for accurate location
    // This ensures the map opens to the correct location, not just the place name
    if (widget.placesService != null && fullDescription.isNotEmpty) {
      final mapLink = widget.placesService!.generateMapLink(fullDescription);
      if (mapLink.isNotEmpty) {
        widget.onMapLinkGenerated?.call(mapLink);
      }
    }

    // Clear suggestions
    if (mounted) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Location',
          border: const OutlineInputBorder(),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.placesService != null
                  ? IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (widget.controller.text.trim().isNotEmpty) {
                          _fetchSuggestions(widget.controller.text);
                        }
                      },
                      tooltip: 'Search location',
                    )
                  : null,
        ),
      ),
    );
  }
}
