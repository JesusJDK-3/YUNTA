import 'dart:math' as math;

import 'yunta_exception.dart';
import 'models.dart';

/// Límites compartidos con el SQL. Si cambian, hay que tocar la migración.
class Limits {
  static const nameMin = 2;
  static const nameMax = 40;
  static const titleMin = 3;
  static const titleMax = 80;
  static const descriptionMax = 500;
  static const messageMax = 500;
  static const commentMax = 280;
  static const areaMax = 40;
  static const reasonMax = 200;
  static const emergencyRadiusM = 500;
  static const distanceStepM = 100;
  static const publicRatingMin = 3;
}

/// Centros de las cuatro zonas. El GPS solo sugiere la más cercana.
const zoneCenters = <String, ViewerPoint>{
  'norte': ViewerPoint(-12.043, -77.04),
  'centro': ViewerPoint(-12.05, -77.04),
  'sur': ViewerPoint(-12.057, -77.04),
  'este': ViewerPoint(-12.05, -77.032),
};

class PublishSpec {
  const PublishSpec({
    required this.kind,
    required this.category,
    required this.type,
    required this.coordinationMode,
    required this.authorRole,
    required this.initialStatus,
  });

  final String kind;
  final String category;
  final String type;
  final String? coordinationMode;

  /// Papel de quien publica. Null en un anuncio: todavía no hay caso.
  final String? authorRole;
  final String initialStatus;
}

/// Una sola tabla de decisión para la interfaz y el SQL.
/// Si se agrega un intento, hay que tocarla aquí y en la migración.
PublishSpec specFromIntent(String intent, [String? helpType]) {
  switch (intent) {
    case 'pido_ayuda':
      return PublishSpec(
        kind: 'caso',
        category: 'ayuda',
        type: helpType ?? 'ayuda_temporal',
        coordinationMode: 'individual',
        authorRole: 'receptor',
        initialStatus: 'abierto',
      );
    case 'ofrezco_ayuda':
      return PublishSpec(
        kind: 'caso',
        category: 'ayuda',
        type: helpType ?? 'ayuda_temporal',
        coordinationMode: 'individual',
        authorRole: 'prestador',
        initialStatus: 'abierto',
      );
    case 'producto':
      return const PublishSpec(
        kind: 'anuncio',
        category: 'producto',
        type: 'producto',
        coordinationMode: null,
        authorRole: null,
        initialStatus: 'activo',
      );
    case 'servicio':
      return const PublishSpec(
        kind: 'anuncio',
        category: 'servicio',
        type: 'servicio',
        coordinationMode: null,
        authorRole: null,
        initialStatus: 'activo',
      );
    case 'emergencia_persona':
      return const PublishSpec(
        kind: 'caso',
        category: 'emergencia',
        type: 'persona',
        coordinationMode: 'individual',
        authorRole: 'receptor',
        initialStatus: 'abierto',
      );
    case 'emergencia_cuadra':
      return const PublishSpec(
        kind: 'caso',
        category: 'emergencia',
        type: 'cuadra',
        coordinationMode: 'grupal',
        authorRole: 'participante',
        initialStatus: 'abierto',
      );
    case 'emergencia_recurso':
      return const PublishSpec(
        kind: 'caso',
        category: 'emergencia',
        type: 'recurso',
        coordinationMode: 'grupal',
        authorRole: 'participante',
        initialStatus: 'abierto',
      );
    case 'grupo_apoyo':
      return const PublishSpec(
        kind: 'anuncio',
        category: 'grupo_de_apoyo',
        type: 'grupo_de_apoyo',
        coordinationMode: null,
        authorRole: null,
        initialStatus: 'activo',
      );
    default:
      throw YuntaException('validation', 'Intento desconocido: $intent');
  }
}

bool isZoneId(String value) => kZones.any((zone) => zone.id == value);

String zoneName(String zoneId) {
  for (final zone in kZones) {
    if (zone.id == zoneId) return zone.name;
  }
  return zoneId;
}

/// Texto plano para guardar. Quita etiquetas, caracteres invisibles y
/// marcas que no son texto del barrio: $ < > / \ { } ` |
/// El mismo filtro corre en SQL, porque la anon key puede llamar la función directo.
String cleanText(String value, int max) {
  final plain = value
      .replaceAll(RegExp(r'<\s*(script|style)\b[^>]*>[\s\S]*?<\s*/\s*\1\s*>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'[$<>/\\{}`|]'), '')
      .replaceAll(
        RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F\u200B-\u200D\u2060\uFEFF\u202A-\u202E\u2066-\u2069]'),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (plain.length <= max) return plain;
  return plain.substring(0, max);
}

/// El muro es público. Un celular o una calle con número se dicen en el chat.
final _privatePhone = RegExp(r'(?:\+?\d[\d\s().-]{7,}\d)');
final _privateStreet = RegExp(
  r'\b(?:calle|avenida|av\.?|jr\.?|jir[oó]n|manzana|mz\.?|lote|pasaje|psje|departamento|dpto)\b[^.\n]{0,40}\d{1,5}|\b\d{1,5}\s+(?:calle|avenida|av\.?|jr\.?|jir[oó]n|pasaje)\b',
  caseSensitive: false,
);

void assertPublicText(String title, String description, [String? areaLabel]) {
  final visible = '$title\n$description';
  if (_privatePhone.hasMatch(visible) || _privateStreet.hasMatch(visible)) {
    throw const YuntaException('private_text');
  }
  if (areaLabel != null && _privateStreet.hasMatch(areaLabel)) {
    throw const YuntaException('private_text');
  }
}

class AnnouncementText {
  const AnnouncementText({required this.title, required this.description, this.areaLabel});
  final String title;
  final String description;
  final String? areaLabel;
}

/// Título, detalle y referencia que pueden verse en el muro.
AnnouncementText parseAnnouncement(String title, String description, [String? areaLabel]) {
  final cleanTitle = cleanText(title, Limits.titleMax);
  final cleanDescription = cleanText(description, Limits.descriptionMax);
  final cleanArea = areaLabel == null || areaLabel.trim().isEmpty ? null : cleanText(areaLabel, Limits.areaMax);
  if (cleanTitle.length < Limits.titleMin || !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(cleanTitle)) {
    throw const YuntaException('validation', 'El título necesita al menos 3 caracteres y una palabra o un número.');
  }
  assertPublicText(cleanTitle, cleanDescription, cleanArea);
  return AnnouncementText(
    title: cleanTitle,
    description: cleanDescription,
    areaLabel: (cleanArea == null || cleanArea.isEmpty) ? null : cleanArea,
  );
}

String parseName(String value) {
  final name = cleanText(value, Limits.nameMax);
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(name).length;
  if (letters < Limits.nameMin || RegExp(r'[0-9@<>]|https?:|www\.', caseSensitive: false).hasMatch(name)) {
    throw const YuntaException('validation', 'El nombre lleva al menos 2 letras, sin números ni enlaces.');
  }
  return name;
}

String parseEmail(String value) {
  final email = cleanText(value, 254).toLowerCase();
  if (!RegExp(r'^[a-z0-9._%+\-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(email)) {
    throw const YuntaException('validation', 'Escribe un correo válido, como nombre@correo.com.');
  }
  return email;
}

String parseZone(String value) {
  if (!isZoneId(value)) throw const YuntaException('validation', 'Elige una zona de la lista.');
  return value;
}

/// La búsqueda solo filtra lo que ya está en pantalla. No vuelve a pedir la red.
String parseSearch(String value) => cleanText(value, 80).toLowerCase();

String parseMessage(String value) {
  final body = cleanText(value, Limits.messageMax);
  if (body.isEmpty) throw const YuntaException('validation', 'Escribe un mensaje antes de enviarlo.');
  return body;
}

String parseReason(String value) {
  final reason = cleanText(value, Limits.reasonMax);
  if (reason.length < 3) throw const YuntaException('validation', 'El reporte necesita al menos 3 caracteres.');
  return reason;
}

String parseComment(String value) => cleanText(value, Limits.commentMax);

int parseScore(num value) {
  if (value is! int && value != value.roundToDouble()) {
    throw const YuntaException('validation', 'La nota es un número del 1 al 5.');
  }
  final score = value.round();
  if (score < 1 || score > 5) {
    throw const YuntaException('validation', 'La nota es un número del 1 al 5.');
  }
  return score;
}

/// Acepta un celular de 8 a 15 dígitos, con o sin +.
/// No exige un país: el reto no está atado a una operadora.
String parsePhone(String value) {
  final compact = value.trim().replaceAll(RegExp(r'[\s()$<>/\\{}`|-]'), '');
  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(compact)) {
    throw const YuntaException('validation', 'Escribe un celular de 8 a 15 dígitos. Puedes incluir el +.');
  }
  return compact.startsWith('+') ? compact : '+$compact';
}

void assertCoords(double? lat, double? lng) {
  final hasLat = lat != null;
  final hasLng = lng != null;
  if (hasLat != hasLng) throw const YuntaException('validation');
  if (lat == null || lng == null) return;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) throw const YuntaException('validation');
}

final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);

PublishInput parsePublish(Map<String, dynamic> input) {
  final intent = input['intent'];
  final helpType = input['helpType'];
  if (intent is! String || !kIntents.contains(intent)) {
    throw const YuntaException('validation', 'Revisa el aviso. Falta un dato o el tipo no es válido.');
  }
  if (helpType != null && (helpType is! String || !kHelpTypes.contains(helpType))) {
    throw const YuntaException('validation', 'Revisa el aviso. Falta un dato o el tipo no es válido.');
  }
  final requestId = input['clientRequestId'];
  if (requestId is! String || !_uuid.hasMatch(requestId)) {
    throw const YuntaException('validation', 'Revisa el aviso. Falta un dato o el tipo no es válido.');
  }
  final text = parseAnnouncement(
    input['title'] is String ? input['title'] as String : '',
    input['description'] is String ? input['description'] as String : '',
    input['areaLabel'] is String ? input['areaLabel'] as String : null,
  );
  if ((intent == 'pido_ayuda' || intent == 'ofrezco_ayuda') && helpType == null) {
    throw const YuntaException('validation', 'Elige el tipo de favor.');
  }
  final lat = (input['lat'] as num?)?.toDouble();
  final lng = (input['lng'] as num?)?.toDouble();
  assertCoords(lat, lng);
  return PublishInput(
    intent: intent,
    helpType: helpType as String?,
    title: text.title,
    description: text.description,
    areaLabel: text.areaLabel,
    lat: lat,
    lng: lng,
    clientRequestId: requestId,
  );
}

/// Redondeo a 100 m. Por debajo de 100 m no decimos "0 m":
/// esa precisión, repetida, ayuda a triangular una casa.
String? distanceLabel(double? meters) {
  if (meters == null || meters.isNaN || meters < 0) return null;
  if (meters < Limits.distanceStepM) return 'A menos de 100 m';
  final rounded = (meters / Limits.distanceStepM).round() * Limits.distanceStepM;
  return 'A unos $rounded m';
}

double _toRad(double value) => value * 3.141592653589793 / 180;

double haversineMeters(ViewerPoint a, ViewerPoint b) {
  const earth = 6371000.0;
  final dLat = _toRad(b.lat - a.lat);
  final dLng = _toRad(b.lng - a.lng);
  final lat1 = _toRad(a.lat);
  final lat2 = _toRad(b.lat);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  final clamped = h > 1 ? 1.0 : h;
  return 2 * earth * math.asin(math.sqrt(clamped));
}

/// Zona sugerida: el centro más cercano. La persona igual tiene que confirmarla.
String nearestZone(double lat, double lng) {
  assertCoords(lat, lng);
  var best = 'centro';
  var bestMeters = double.infinity;
  for (final entry in zoneCenters.entries) {
    final meters = haversineMeters(ViewerPoint(lat, lng), entry.value);
    if (meters < bestMeters) {
      best = entry.key;
      bestMeters = meters;
    }
  }
  return best;
}

class PublicRating {
  const PublicRating({required this.ratingCount, required this.ratingAverage});
  final int ratingCount;
  final double? ratingAverage;
}

/// La nota pública aparece desde la tercera valoración.
PublicRating publicRating(int count, double? average) {
  if (count < Limits.publicRatingMin || average == null) {
    return const PublicRating(ratingCount: 0, ratingAverage: null);
  }
  return PublicRating(ratingCount: count, ratingAverage: (average * 10).round() / 10);
}

String statusLabel(String status) {
  const labels = {
    'activo': 'Activo',
    'retirado': 'Retirado',
    'abierto': 'Abierto',
    'en_coordinacion': 'En coordinación',
    'resuelto': 'Resuelto',
    'cancelado': 'Cancelado',
  };
  return labels[status] ?? status;
}

String? modeLabel(String? mode) {
  if (mode == null) return null;
  if (mode == 'individual') return 'Entre dos';
  if (mode == 'grupal') return 'En grupo';
  return mode;
}
