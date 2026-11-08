import 'models.dart';

/// En una emergencia el muro se parte en tres.
/// El tablero humanitario junta a la persona y a la cuadra.
/// La economía solidaria es solo el recurso crítico.
/// Los grupos de apoyo quedan en su propio directorio.
class EmergencyBoards {
  const EmergencyBoards({
    required this.humanitario,
    required this.solidaria,
    required this.apoyo,
  });

  final List<FeedItem> humanitario;
  final List<FeedItem> solidaria;
  final List<FeedItem> apoyo;
}

EmergencyBoards splitEmergencyBoard(List<FeedItem> items) {
  final humanitario = <FeedItem>[];
  final solidaria = <FeedItem>[];
  final apoyo = <FeedItem>[];
  for (final item in items) {
    if (item.category == 'grupo_de_apoyo' || item.type == 'grupo_de_apoyo') {
      apoyo.add(item);
    } else if (item.type == 'recurso') {
      solidaria.add(item);
    } else {
      humanitario.add(item);
    }
  }
  return EmergencyBoards(humanitario: humanitario, solidaria: solidaria, apoyo: apoyo);
}

/// Aviso de lo que se envió al volver la señal. El singular y el plural van aparte.
String? sentNotice(int posts, int messages) {
  final bits = <String>[];
  if (posts == 1) {
    bits.add('1 aviso');
  } else if (posts > 1) {
    bits.add('$posts avisos');
  }
  if (messages == 1) {
    bits.add('1 mensaje');
  } else if (messages > 1) {
    bits.add('$messages mensajes');
  }
  if (bits.isEmpty) return null;
  final total = posts + messages;
  final verb = total == 1 ? 'Se envió' : 'Se enviaron';
  final tail = total == 1 ? 'que estaba pendiente' : 'que estaban pendientes';
  return '$verb ${bits.join(' y ')} $tail.';
}
