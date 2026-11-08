/// Error de dominio con un código estable.
/// La pantalla muestra [message]. El texto crudo de Postgres no llega al vecino.
class YuntaException implements Exception {
  const YuntaException(this.code, [String? message]) : message = message ?? '';

  final String code;

  /// Vacío cuando hay que usar [messageFor].
  final String message;

  String get text => message.isEmpty ? messageFor(code) : message;

  @override
  String toString() => 'YuntaException($code): $text';
}

const _messages = <String, String>{
  'unauthenticated': 'Entra de nuevo para continuar.',
  'profile_required': 'Falta tu nombre y tu zona.',
  'validation': 'Revisa los datos. Hay algún campo demasiado corto o demasiado largo.',
  'forbidden': 'No puedes hacer eso en este aviso.',
  'not_found': 'Ese aviso ya no está.',
  'conflict': 'Esa acción ya estaba hecha.',
  'rate_limit': 'Vas muy rápido. Espera un momento y vuelve a intentar.',
  'location_required': 'Para ver emergencias cercanas, permite la ubicación o elige tu zona.',
  'slot_taken': 'Ya hay alguien en esta coordinación.',
  'chat_closed': 'Este chat ya no recibe mensajes.',
  'self_action': 'No puedes hacerte eso a ti mismo.',
  'blocked': 'Esa coordinación no está disponible.',
  'zone_mismatch': 'El visto bueno es entre vecinos de la misma zona.',
  'private_text': 'No publiques celulares ni direcciones exactas. Compártelos en el chat.',
  'network': 'Sin conexión. El aviso quedó en este celular y se enviará al volver la señal.',
  'unexpected': 'Algo falló. Inténtalo otra vez.',
};

String messageFor(String code) => _messages[code] ?? _messages['unexpected']!;

/// Traduce `YUNTA:codigo` que lanzan las funciones SQL, o un fallo de red.
YuntaException fromRemoteMessage(String raw) {
  final match = RegExp(r'YUNTA:([a-z_]+)').firstMatch(raw);
  final code = match?.group(1) ?? (isNetworkMessage(raw) ? 'network' : 'unexpected');
  return YuntaException(code);
}

bool isNetworkMessage(String raw) {
  final text = raw.toLowerCase();
  return text.contains('failed to fetch') ||
      text.contains('failed host') ||
      text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('offline') ||
      text.contains('timed out');
}

YuntaException asYunta(Object error) {
  if (error is YuntaException) return error;
  return fromRemoteMessage(error.toString());
}
