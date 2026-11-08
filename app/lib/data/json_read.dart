import '../domain/models.dart';
import '../domain/yunta_exception.dart';

/// Lectura defensiva del JSON que devuelve Supabase.
/// Un campo nuevo no rompe la pantalla. Un id ausente sí: no hay aviso que mostrar.

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const YuntaException('unexpected');
}

List<dynamic> asList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value;
  throw const YuntaException('unexpected');
}

String _str(dynamic value, [String fallback = '']) => value?.toString() ?? fallback;

String? _strOrNull(dynamic value) => value?.toString();

int _int(dynamic value) => value is num ? value.toInt() : 0;

double? _double(dynamic value) => value is num ? value.toDouble() : null;

bool _bool(dynamic value) => value == true;

FeedItem parseFeedItem(dynamic value) {
  final json = asMap(value);
  final id = _strOrNull(json['id']);
  final title = _strOrNull(json['title']);
  if (id == null || title == null || id.isEmpty || title.isEmpty) {
    throw const YuntaException('unexpected');
  }
  return FeedItem(
    id: id,
    kind: _str(json['kind']),
    category: _str(json['category']),
    type: _str(json['type']),
    title: title,
    description: _str(json['description']),
    zoneId: _str(json['zoneId']),
    zoneName: _str(json['zoneName'], 'Zona'),
    areaLabel: _str(json['areaLabel']),
    distanceLabel: _strOrNull(json['distanceLabel']),
    coordinationMode: _strOrNull(json['coordinationMode']),
    status: _str(json['status']),
    recommendationCount: _int(json['recommendationCount']),
    ratingAverage: _double(json['ratingAverage']),
    ratingCount: _int(json['ratingCount']),
    authorId: _str(json['authorId']),
    authorName: _str(json['authorName'], 'Vecino'),
    sourceAnuncioId: _strOrNull(json['sourceAnuncioId']),
    createdAt: _str(json['createdAt']),
  );
}

FeedResult parseFeed(dynamic value) {
  final json = asMap(value);
  final items = <FeedItem>[];
  for (final row in asList(json['items'])) {
    try {
      items.add(parseFeedItem(row));
    } on YuntaException {
      // Una fila mal formada no vacía el muro entero.
    }
  }
  return FeedResult(items: items, needsLocation: _bool(json['needsLocation']));
}

MemberView _member(dynamic value) {
  final json = asMap(value);
  return MemberView(
    userId: _str(json['userId']),
    displayName: _str(json['displayName'], 'Vecino'),
    role: _str(json['role']),
    status: _str(json['status']),
  );
}

MessageView _message(dynamic value) {
  final json = asMap(value);
  return MessageView(
    id: _str(json['id']),
    senderId: _str(json['senderId']),
    senderName: _str(json['senderName'], 'Vecino'),
    body: _str(json['body']),
    createdAt: _str(json['createdAt']),
  );
}

Detail parseDetail(dynamic value) {
  final json = asMap(value);
  RatingView? rating;
  final rawRating = json['myRating'];
  if (rawRating is Map) {
    rating = RatingView(score: _int(rawRating['score']), comment: _str(rawRating['comment']));
  }
  return Detail(
    item: parseFeedItem(json['item']),
    members: asList(json['members']).map(_member).toList(),
    pending: asList(json['pending']).map(_member).toList(),
    messages: asList(json['messages']).where((row) => asMap(row)['id'] != null).map(_message).toList(),
    myRole: _strOrNull(json['myRole']),
    myStatus: _strOrNull(json['myStatus']),
    isAuthor: _bool(json['isAuthor']),
    chatOpen: _bool(json['chatOpen']),
    canSend: _bool(json['canSend']),
    canRecommend: _bool(json['canRecommend']),
    alreadyRecommended: _bool(json['alreadyRecommended']),
    canOfferHelp: _bool(json['canOfferHelp']),
    canRequestHelp: _bool(json['canRequestHelp']),
    canJoinGroup: _bool(json['canJoinGroup']),
    canResolve: _bool(json['canResolve']),
    canCancel: _bool(json['canCancel']),
    canReopen: _bool(json['canReopen']),
    canSharePhone: _bool(json['canSharePhone']),
    canEdit: _bool(json['canEdit']),
    canRetire: _bool(json['canRetire']),
    canRate: _bool(json['canRate']),
    myRating: rating,
  );
}

Session? parseSession(dynamic value) {
  if (value == null) return null;
  final json = asMap(value);
  final userId = _strOrNull(json['userId']);
  final zoneId = _strOrNull(json['zoneId']);
  if (userId == null || zoneId == null) throw const YuntaException('unexpected');
  return Session(
    userId: userId,
    displayName: _str(json['displayName'], 'Vecino'),
    zoneId: zoneId,
    zoneName: _str(json['zoneName'], zoneId),
  );
}

CreatedRef parseCreated(dynamic value) {
  final json = asMap(value);
  final id = _strOrNull(json['id']);
  if (id == null || id.isEmpty) throw const YuntaException('unexpected');
  return CreatedRef(id: id, deduped: _bool(json['deduped']));
}

List<BlockView> parseBlocks(dynamic value) {
  return asList(value)
      .map((row) {
        final json = asMap(row);
        return BlockView(userId: _str(json['userId']), displayName: _str(json['displayName'], 'Vecino'));
      })
      .where((row) => row.userId.isNotEmpty)
      .toList();
}

List<ZoneOption> parseZones(dynamic value) {
  final zones = <ZoneOption>[];
  for (final row in asList(value)) {
    final json = asMap(row);
    final id = _strOrNull(json['id']);
    if (id == null) continue;
    zones.add(ZoneOption(id, _str(json['name'], id)));
  }
  return zones;
}
