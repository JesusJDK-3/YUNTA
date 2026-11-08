import 'package:flutter_test/flutter_test.dart';
import 'package:yunta/data/ids.dart';
import 'package:yunta/domain/boards.dart';
import 'package:yunta/domain/choices.dart';
import 'package:yunta/domain/models.dart';
import 'package:yunta/domain/rules.dart';
import 'package:yunta/domain/yunta_exception.dart';

void main() {
  test('el oficio queda como anuncio y la muleta como caso entre dos', () {
    final oficio = specFromIntent('servicio');
    expect(oficio.kind, 'anuncio');
    expect(oficio.authorRole, isNull);

    final muleta = specFromIntent('pido_ayuda', 'herramienta');
    expect(muleta.kind, 'caso');
    expect(muleta.coordinationMode, 'individual');
    expect(muleta.authorRole, 'receptor');

    final cuadra = specFromIntent('emergencia_cuadra');
    expect(cuadra.coordinationMode, 'grupal');
    expect(cuadra.authorRole, 'participante');
    expect(specFromIntent('emergencia_persona').coordinationMode, 'individual');
  });

  test('la distancia se redondea y no dice 0 m', () {
    expect(distanceLabel(40), 'A menos de 100 m');
    expect(distanceLabel(240), 'A unos 200 m');
    expect(distanceLabel(250), 'A unos 300 m');
    expect(distanceLabel(null), isNull);
  });

  test('Norte y Centro se separan por más de 500 m', () {
    final meters = haversineMeters(zoneCenters['norte']!, zoneCenters['centro']!);
    expect(meters, greaterThan(500));
    expect(nearestZone(zoneCenters['norte']!.lat, zoneCenters['norte']!.lng), 'norte');
  });

  test('limpia etiquetas y rechaza nombre o correo inválido', () {
    expect(cleanText('  Hola<script>x</script>  <b>vecino</b>  ', 80), 'Hola vecino');
    expect(cleanText(r'a$b<c/d\e{f}`g|h', 80), 'abcdefgh');
    expect(cleanText('Ana\u200B López', 40), 'Ana López');
    expect(parseName('Ana López'), 'Ana López');
    expect(() => parseName('12345'), throwsA(isA<YuntaException>()));
    expect(parseEmail('  Nombre@Correo.com '), 'nombre@correo.com');
    expect(() => parseEmail('no es correo'), throwsA(isA<YuntaException>()));
  });

  test('rechaza un título corto y un teléfono imposible', () {
    expect(
      () => parsePublish({
        'intent': 'servicio',
        'title': 'ab',
        'description': 'oficio',
        'clientRequestId': newId(),
      }),
      throwsA(isA<YuntaException>()),
    );
    expect(parsePhone('987 654 321'), '+987654321');
    expect(() => parsePhone('12'), throwsA(isA<YuntaException>()));
  });

  test('no deja un celular ni una calle numerada en el muro', () {
    expect(() => assertPublicText('Gasfiter', 'Llámame al 987 654 321'), throwsA(isA<YuntaException>()));
    expect(() => assertPublicText('Ayuda', 'Estoy en calle Los Pinos 120'), throwsA(isA<YuntaException>()));
    expect(() => assertPublicText('Baldes', 'Hacen falta 2 baldes'), returnsNormally);
  });

  test('guarda el promedio solo desde la tercera nota', () {
    expect(publicRating(2, 5).ratingAverage, isNull);
    expect(publicRating(3, 4.26).ratingAverage, 4.3);
  });

  test('separa el tablero humanitario, la economía solidaria y los grupos', () {
    FeedItem item(String id, String category, String type, String title) {
      return FeedItem(
        id: id,
        kind: 'caso',
        category: category,
        type: type,
        title: title,
        description: '',
        zoneId: 'centro',
        zoneName: 'Zona Centro',
        areaLabel: 'Zona Centro',
        distanceLabel: 'A unos 200 m',
        coordinationMode: 'grupal',
        status: 'abierto',
        recommendationCount: 0,
        ratingAverage: null,
        ratingCount: 0,
        authorId: '11111111-1111-4111-8111-111111111111',
        authorName: 'Ana',
        sourceAnuncioId: null,
        createdAt: '2026-11-08T00:00:00.000Z',
      );
    }

    final boards = splitEmergencyBoard([
      item('11111111-1111-4111-8111-111111111111', 'emergencia', 'persona', 'Persona'),
      item('22222222-2222-4222-8222-222222222222', 'emergencia', 'cuadra', 'Cuadra'),
      item('33333333-3333-4333-8333-333333333333', 'emergencia', 'recurso', 'Agua'),
      item('44444444-4444-4444-8444-444444444444', 'grupo_de_apoyo', 'grupo_de_apoyo', 'Posta'),
    ]);
    expect(boards.humanitario.map((row) => row.title), ['Persona', 'Cuadra']);
    expect(boards.solidaria.map((row) => row.title), ['Agua']);
    expect(boards.apoyo.map((row) => row.title), ['Posta']);
  });

  test('cada aviso es una sola opción', () {
    for (final type in kHelpTypes) {
      expect(kPublishChoices.any((choice) => choice.intent == 'pido_ayuda' && choice.helpType == type), isTrue);
      expect(kPublishChoices.any((choice) => choice.intent == 'ofrezco_ayuda' && choice.helpType == type), isTrue);
    }
    for (final intent in ['servicio', 'producto', 'emergencia_persona', 'emergencia_cuadra', 'emergencia_recurso', 'grupo_apoyo']) {
      expect(kPublishChoices.where((choice) => choice.intent == intent).length, 1);
    }
  });

  test('nombra aviso y mensaje por separado', () {
    expect(sentNotice(0, 0), isNull);
    expect(sentNotice(1, 0), 'Se envió 1 aviso que estaba pendiente.');
    expect(sentNotice(2, 1), 'Se enviaron 2 avisos y 1 mensaje que estaban pendientes.');
  });
}
