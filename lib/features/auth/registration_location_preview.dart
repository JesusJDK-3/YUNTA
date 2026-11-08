import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';

class RegistrationLocationPreview extends StatelessWidget {
  const RegistrationLocationPreview({required this.point, super.key});

  final LocationPoint point;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(point.latitude, point.longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 198,
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14.6),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yunta.vecinal',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: 500,
                      useRadiusInMeter: true,
                      color: YuntaColors.action.withValues(alpha: .16),
                      borderColor: YuntaColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.location_on,
                        color: YuntaColors.primary,
                        size: 38,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(
              Icons.radio_button_checked,
              size: 16,
              color: YuntaColors.primary,
            ),
            SizedBox(width: 7),
            Text('Tu zona cercana · 500 m'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'OpenStreetMap recibe solicitudes para cargar el mapa de la zona visible.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
