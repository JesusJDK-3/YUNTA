import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_point.dart';
import '../../core/theme/yunta_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({this.initialPoint, super.key});

  final LocationPoint? initialPoint;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _peruView = LatLng(-9.19, -75.015);
  LocationPoint? _selected;

  LatLng get _initialCenter => widget.initialPoint == null
      ? _peruView
      : LatLng(widget.initialPoint!.latitude, widget.initialPoint!.longitude);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Elige tu ubicación')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text('Mueve el mapa y toca el punto aproximado donde vives.'),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: widget.initialPoint == null ? 5 : 15,
              onTap: (_, point) => setState(() {
                _selected = LocationPoint(
                  latitude: point.latitude,
                  longitude: point.longitude,
                );
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yunta.vecinal',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_selected!.latitude, _selected!.longitude),
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        size: 42,
                        color: YuntaColors.ink,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              if (_selected == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Toca el mapa para elegir el punto.'),
                ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'OpenStreetMap recibe solicitudes para cargar la zona visible '
                  'del mapa. Al completar el registro, Yunta guarda el punto '
                  'elegido en tu perfil privado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: const Text('Confirmar ubicación'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
