import 'dart:convert';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/yunta_exception.dart';
import 'ids.dart';
import 'json_read.dart';
import 'key_value.dart';
import 'yunta_api.dart';

/// Copia local para cuando se corta la red.
/// El muro y la ficha se vuelven a leer de aquí.
/// El aviso y el mensaje salen al volver la señal, con el mismo identificador.
class OfflineYunta implements YuntaApi {
  OfflineYunta(this._inner, this._store);

  final YuntaApi _inner;
  final KeyValue _store;
  static const _key = 'yunta.offline.v1';
  static const _detailLimit = 30;

  /// Una sola escritura a la vez. Si no, un refresco y un envío se pisan la cola.
  Future<void> _queue = Future<void>.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final run = _queue.then((_) => action());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  Map<String, dynamic> _read() {
    try {
      final raw = _store.getString(_key);
      if (raw == null || raw.isEmpty) return _empty();
      final parsed = jsonDecode(raw);
      if (parsed is! Map) return _empty();
      return Map<String, dynamic>.from(parsed);
    } catch (_) {
      return _empty();
    }
  }

  Map<String, dynamic> _empty() => {
        'feeds': <String, dynamic>{},
        'details': <dynamic>[],
        'messages': <dynamic>[],
        'publishes': <dynamic>[],
        'session': null,
      };

  Future<void> _write(Map<String, dynamic> snapshot) => _store.setString(_key, jsonEncode(snapshot));

  @override
  Future<Session?> currentSession() => _locked(() async {
    try {
      final session = await _inner.currentSession();
      final snapshot = _read();
      snapshot['session'] = session == null
          ? null
          : {
              'userId': session.userId,
              'displayName': session.displayName,
              'zoneId': session.zoneId,
              'zoneName': session.zoneName,
            };
      await _write(snapshot);
      return session;
    } catch (error) {
      final yunta = asYunta(error);
      if (yunta.code != 'network') throw yunta;
      final cached = _read()['session'];
      if (cached == null) {
        throw const YuntaException('network', 'Sin conexión. Cuando vuelva la señal podrás entrar.');
      }
      return parseSession(cached);
    }
  });

  @override
  Future<String?> pendingEmail() => _locked(() async {
    try {
      return await _inner.pendingEmail();
    } catch (error) {
      final yunta = asYunta(error);
      if (yunta.code != 'network') throw yunta;
      if (_read()['session'] != null) return null;
      throw const YuntaException('network', 'Sin conexión. Cuando vuelva la señal podrás entrar con el enlace del correo.');
    }
  });

  @override
  Future<void> signOut() => _locked(() async {
        await _store.remove(_key);
        await _inner.signOut();
      });

  @override
  Future<FeedResult> feed(String tab, ViewerPoint? point) => _locked(() async {
    try {
      final result = await _inner.feed(tab, point);
      final snapshot = _read();
      final feeds = Map<String, dynamic>.from(snapshot['feeds'] as Map? ?? {});
      feeds[tab] = {
        'items': result.items.map(_itemJson).toList(),
        'needsLocation': result.needsLocation,
      };
      snapshot['feeds'] = feeds;
      await _write(snapshot);
      return result;
    } catch (error) {
      final yunta = asYunta(error);
      if (yunta.code != 'network') throw yunta;
      final feeds = _read()['feeds'];
      final raw = feeds is Map ? feeds[tab] : null;
      if (raw == null) {
        throw const YuntaException('network', 'Sin conexión y todavía no hay una lista guardada en este celular.');
      }
      try {
        final cached = parseFeed(raw);
        return FeedResult(items: cached.items, needsLocation: cached.needsLocation, offline: true);
      } catch (_) {
        throw const YuntaException('network', 'Sin conexión y todavía no hay una lista guardada en este celular.');
      }
    }
  });

  @override
  Future<Detail> detail(String id) => _locked(() async {
    try {
      final value = await _inner.detail(id);
      final snapshot = _read();
      final rows = List<dynamic>.from(snapshot['details'] as List? ?? []);
      rows.removeWhere((row) => row is Map && row['id'] == id);
      rows.add({'id': id, 'detail': _detailJson(value), 'savedAt': DateTime.now().toIso8601String()});
      snapshot['details'] = rows.length > _detailLimit ? rows.sublist(rows.length - _detailLimit) : rows;
      await _write(snapshot);
      return _withPending(value, false);
    } catch (error) {
      final yunta = asYunta(error);
      if (yunta.code != 'network') throw yunta;
      final rows = _read()['details'];
      if (rows is! List) {
        throw const YuntaException('network', 'Sin conexión y este aviso no está guardado en el celular.');
      }
      for (final row in rows.reversed) {
        if (row is Map && row['id'] == id) {
          try {
            return _withPending(parseDetail(row['detail']), true);
          } catch (_) {
            break;
          }
        }
      }
      throw const YuntaException('network', 'Sin conexión y este aviso no está guardado en el celular.');
    }
  });

  @override
  Future<CreatedRef> publish(PublishInput input) => _locked(() async {
    final parsed = parsePublish(input.toJson());
    try {
      final created = await _inner.publish(parsed);
      await _dropPublish(parsed.clientRequestId);
      return created;
    } catch (error) {
      final yunta = asYunta(error);
      if (yunta.code != 'network') throw yunta;
      final snapshot = _read();
      final rows = List<dynamic>.from(snapshot['publishes'] as List? ?? []);
      rows.removeWhere((row) => row is Map && row['clientRequestId'] == parsed.clientRequestId);
      rows.add(parsed.toJson());
      snapshot['publishes'] = rows;
      await _write(snapshot);
      throw yunta;
    }
  });

  @override
  Future<void> sendMessage(String casoId, String body) => _locked(() async {
    final parsed = parseMessage(body);
    try {
      await _inner.sendMessage(casoId, parsed);
    } catch (error) {
      final yunta = asYunta(error);
      if (yunta.code != 'network') throw yunta;
      final snapshot = _read();
      final rows = List<dynamic>.from(snapshot['messages'] as List? ?? []);
      rows.add({
        'casoId': casoId,
        'body': parsed,
        'localId': newId(),
        'savedAt': DateTime.now().toIso8601String(),
      });
      snapshot['messages'] = rows;
      await _write(snapshot);
    }
  });

  @override
  Future<int> pendingPublishes() => _locked(() async {
    final rows = _read()['publishes'];
    return rows is List ? rows.length : 0;
  });

  @override
  Future<int> pendingMessages() => _locked(() async {
    final rows = _read()['messages'];
    return rows is List ? rows.length : 0;
  });

  @override
  Future<int> flushPublishes() => _locked(() async {
    final pending = List<dynamic>.from(_read()['publishes'] as List? ?? []);
    final failed = <String>{};
    var sent = 0;
    for (final row in pending) {
      if (row is! Map) continue;
      final input = PublishInput.fromJson(Map<String, dynamic>.from(row));
      try {
        await _inner.publish(input);
        sent += 1;
      } catch (error) {
        if (asYunta(error).code == 'network') failed.add(input.clientRequestId);
      }
    }
    final snapshot = _read();
    final latest = List<dynamic>.from(snapshot['publishes'] as List? ?? []);
    snapshot['publishes'] = latest.where((row) {
      if (row is! Map) return false;
      final id = row['clientRequestId'];
      final wasPending = pending.any((item) => item is Map && item['clientRequestId'] == id);
      if (!wasPending) return true;
      return failed.contains(id);
    }).toList();
    await _write(snapshot);
    return sent;
  });

  @override
  Future<int> flushMessages() => _locked(() async {
    final pending = List<dynamic>.from(_read()['messages'] as List? ?? []);
    final failed = <String>{};
    var sent = 0;
    for (final row in pending) {
      if (row is! Map) continue;
      final localId = row['localId']?.toString() ?? '';
      try {
        await _inner.sendMessage(row['casoId'].toString(), row['body'].toString());
        sent += 1;
      } catch (error) {
        if (asYunta(error).code == 'network') failed.add(localId);
      }
    }
    final snapshot = _read();
    final latest = List<dynamic>.from(snapshot['messages'] as List? ?? []);
    snapshot['messages'] = latest.where((row) {
      if (row is! Map) return false;
      final id = row['localId']?.toString() ?? '';
      final wasPending = pending.any((item) => item is Map && item['localId'] == id);
      if (!wasPending) return true;
      return failed.contains(id);
    }).toList();
    await _write(snapshot);
    return sent;
  });

  @override
  Future<List<BlockView>> blocks() async {
    try {
      return await _inner.blocks();
    } catch (error) {
      if (asYunta(error).code == 'network') return const [];
      throw asYunta(error);
    }
  }

  Future<void> _dropPublish(String id) async {
    final snapshot = _read();
    final rows = List<dynamic>.from(snapshot['publishes'] as List? ?? []);
    rows.removeWhere((row) => row is Map && row['clientRequestId'] == id);
    snapshot['publishes'] = rows;
    await _write(snapshot);
  }

  Detail _withPending(Detail detail, bool offline) {
    final rows = _read()['messages'];
    if (rows is! List) return detail.copyWith(offline: offline);
    final extra = <MessageView>[];
    for (final row in rows) {
      if (row is! Map || row['casoId'] != detail.item.id) continue;
      extra.add(MessageView(
        id: row['localId'].toString(),
        senderId: '00000000-0000-0000-0000-000000000000',
        senderName: 'Tú',
        body: row['body'].toString(),
        createdAt: row['savedAt'].toString(),
        pending: true,
      ));
    }
    final kept = detail.messages.where((message) => !message.pending).toList();
    return detail.copyWith(messages: [...kept, ...extra], offline: offline);
  }

  Map<String, dynamic> _itemJson(FeedItem item) => {
        'id': item.id,
        'kind': item.kind,
        'category': item.category,
        'type': item.type,
        'title': item.title,
        'description': item.description,
        'zoneId': item.zoneId,
        'zoneName': item.zoneName,
        'areaLabel': item.areaLabel,
        'distanceLabel': item.distanceLabel,
        'coordinationMode': item.coordinationMode,
        'status': item.status,
        'recommendationCount': item.recommendationCount,
        'ratingAverage': item.ratingAverage,
        'ratingCount': item.ratingCount,
        'authorId': item.authorId,
        'authorName': item.authorName,
        'sourceAnuncioId': item.sourceAnuncioId,
        'createdAt': item.createdAt,
      };

  Map<String, dynamic> _detailJson(Detail detail) => {
        'item': _itemJson(detail.item),
        'members': detail.members
            .map((m) => {'userId': m.userId, 'displayName': m.displayName, 'role': m.role, 'status': m.status})
            .toList(),
        'pending': detail.pending
            .map((m) => {'userId': m.userId, 'displayName': m.displayName, 'role': m.role, 'status': m.status})
            .toList(),
        'messages': detail.messages
            .where((m) => !m.pending)
            .map((m) => {
                  'id': m.id,
                  'senderId': m.senderId,
                  'senderName': m.senderName,
                  'body': m.body,
                  'createdAt': m.createdAt,
                })
            .toList(),
        'myRole': detail.myRole,
        'myStatus': detail.myStatus,
        'isAuthor': detail.isAuthor,
        'chatOpen': detail.chatOpen,
        'canSend': detail.canSend,
        'canRecommend': detail.canRecommend,
        'alreadyRecommended': detail.alreadyRecommended,
        'canOfferHelp': detail.canOfferHelp,
        'canRequestHelp': detail.canRequestHelp,
        'canJoinGroup': detail.canJoinGroup,
        'canResolve': detail.canResolve,
        'canCancel': detail.canCancel,
        'canReopen': detail.canReopen,
        'canSharePhone': detail.canSharePhone,
        'canEdit': detail.canEdit,
        'canRetire': detail.canRetire,
        'canRate': detail.canRate,
        'myRating': detail.myRating == null
            ? null
            : {'score': detail.myRating!.score, 'comment': detail.myRating!.comment},
      };

  @override
  Future<List<ZoneOption>> listZones() => _inner.listZones();

  @override
  Future<void> requestMagicLink(String email) => _inner.requestMagicLink(email);

  @override
  Future<Session> saveProfile(String displayName, String zoneId) => _inner.saveProfile(displayName, zoneId);

  @override
  Future<CreatedRef> coordinate(String anuncioId, String clientRequestId) =>
      _inner.coordinate(anuncioId, clientRequestId);

  @override
  Future<void> requestEntry(String casoId) => _inner.requestEntry(casoId);

  @override
  Future<void> accept(String casoId, String userId) => _inner.accept(casoId, userId);

  @override
  Future<void> reject(String casoId, String userId) => _inner.reject(casoId, userId);

  @override
  Future<void> joinGroup(String casoId) => _inner.joinGroup(casoId);

  @override
  Future<void> removeMember(String casoId, String userId) => _inner.removeMember(casoId, userId);

  @override
  Future<void> resolve(String casoId) => _inner.resolve(casoId);

  @override
  Future<void> cancel(String id) => _inner.cancel(id);

  @override
  Future<void> reopen(String casoId) => _inner.reopen(casoId);

  @override
  Future<void> editAnuncio(String id, String title, String description) =>
      _inner.editAnuncio(id, title, description);

  @override
  Future<void> recommend(String anuncioId) => _inner.recommend(anuncioId);

  @override
  Future<void> rate(String casoId, int score, String comment) => _inner.rate(casoId, score, comment);

  @override
  Future<void> report(String targetType, String targetId, String reason) =>
      _inner.report(targetType, targetId, reason);

  @override
  Future<void> block(String userId) => _inner.block(userId);

  @override
  Future<void> unblock(String userId) => _inner.unblock(userId);

  @override
  Future<void> sharePhone(String casoId, String phone) => _inner.sharePhone(casoId, phone);

  @override
  void Function() subscribeMessages(String casoId, void Function() onChange) =>
      _inner.subscribeMessages(casoId, onChange);

  @override
  void Function() watchSession(void Function() onChange) => _inner.watchSession(onChange);
}
