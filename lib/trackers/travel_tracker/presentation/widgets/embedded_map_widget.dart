import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget for displaying a location on an embedded map.
/// Uses a placeholder - full implementation would use google_maps_flutter.
class EmbeddedMapWidget extends StatelessWidget {
  final String? location;
  final String? mapLink;

  const EmbeddedMapWidget({
    super.key,
    this.location,
    this.mapLink,
  });

  @override
  Widget build(BuildContext context) {
    if (location == null && mapLink == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: InkWell(
        onTap: mapLink != null
            ? () async {
                final uri = Uri.parse(mapLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }
            : null,
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
              if (location != null)
                Text(
                  location!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              if (mapLink != null)
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
}

