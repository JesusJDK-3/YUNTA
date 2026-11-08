import 'package:geolocator/geolocator.dart';

import 'domain/models.dart';

/// El punto vive solo en memoria.
/// No se escribe en el perfil ni en el disco: sirve para ordenar
/// y para el radio de 500 m, y se olvida al cerrar la app.
/// La precisión fina va apagada: llega antes y es menos exacta.
Future<ViewerPoint?> readPlace() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    return null;
  }
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return ViewerPoint(position.latitude, position.longitude);
  } catch (_) {
    // Tiempo agotado o el sistema negó el punto. La zona sigue valiendo.
    return null;
  }
}
