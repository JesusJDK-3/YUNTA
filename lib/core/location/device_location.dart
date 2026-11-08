import 'package:geolocator/geolocator.dart';

import 'location_point.dart';

class LocationAccessException implements Exception {
  const LocationAccessException(
    this.message, {
    this.openSettings = false,
    this.deviceSettings = false,
  });

  final String message;
  final bool openSettings;
  final bool deviceSettings;

  @override
  String toString() => message;
}

abstract final class DeviceLocation {
  static Future<LocationPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(
        'Activa la ubicación del teléfono e inténtalo de nuevo.',
        deviceSettings: true,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationAccessException(
        'Necesitamos permiso de ubicación para encontrar vecinos cercanos.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessException(
        'El permiso está bloqueado. Puedes habilitarlo en los ajustes de la app.',
        openSettings: true,
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const LocationAccessException(
        'No se pudo obtener la ubicación. Comprueba la señal GPS e inténtalo otra vez.',
      );
    }
  }

  static Future<void> openSettings({bool device = false}) async {
    if (device) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
