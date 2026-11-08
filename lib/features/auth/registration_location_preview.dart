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
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14.6,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      alignment: AttributionAlignment.bottomRight,
                    ),
                  ],
                ),
                Positioned(
                  left: 11,
                  right: 76,
                  bottom: 11,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16001F2A),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_off_outlined, size: 18),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Punto exacto oculto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'OpenStreetMap recibe solicitudes para cargar el mapa de la zona visible.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
