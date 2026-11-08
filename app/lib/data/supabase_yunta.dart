import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../domain/models.dart';
import '../domain/rules.dart';
import '../domain/yunta_exception.dart';
import 'json_read.dart';
import 'yunta_api.dart';

/// Cliente de Supabase.
/// La pantalla no arma SQL. Cada acción es una función con SECURITY DEFINER
/// y no devuelve el punto.
class SupabaseYunta implements YuntaApi {
  SupabaseYunta(this._client);

  final SupabaseClient _client;

  /// En el navegador el enlace vuelve a esta misma página.
  /// En el teléfono vuelve a la app por el esquema yunta://.
  String get _redirect => kIsWeb ? Uri.base.origin : 'yunta://login-callback';

  Future<dynamic> _rpc(String fn, [Map<String, dynamic> args = const {}]) async {
    try {
      return await _client.rpc(fn, params: args);
    } catch (error) {
      throw asYunta(error);
    }
  }

  @override
  Future<List<ZoneOption>> listZones() async {
    try {
      final rows = parseZones(await _rpc('listar_zonas'));
      return rows.isEmpty ? kZones : rows;
    } catch (error) {
      if (asYunta(error).code == 'network') return kZones;
      throw asYunta(error);
    }
  }

  @override
  Future<Session?> currentSession() async {
    if (_client.auth.currentUser == null) return null;
    return parseSession(await _rpc('mi_perfil'));
  }

  @override
  Future<String?> pendingEmail() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = parseSession(await _rpc('mi_perfil'));
    return profile == null ? user.email : null;
  }

  @override
  Future<void> requestMagicLink(String email) async {
    final parsed = parseEmail(email);
    try {
      await _client.auth.signInWithOtp(email: parsed, emailRedirectTo: _redirect);
    } catch (error) {
      throw asYunta(error);
    }
  }

  @override
  Future<Session> saveProfile(String displayName, String zoneId) async {
    await _rpc('guardar_perfil', {'p_name': parseName(displayName), 'p_zone_id': parseZone(zoneId)});
    final session = parseSession(await _rpc('mi_perfil'));
    if (session == null) throw const YuntaException('profile_required');
    return session;
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      if (asYunta(error).code != 'network') throw asYunta(error);
    }
  }

  @override
  Future<FeedResult> feed(String tab, ViewerPoint? point) {
    return _rpc('feed_muro', {
      'p_tab': tab,
      'p_lat': point?.lat,
      'p_lng': point?.lng,
    }).then(parseFeed);
  }

  @override
  Future<Detail> detail(String id) => _rpc('detalle', {'p_id': id}).then(parseDetail);

  @override
  Future<CreatedRef> publish(PublishInput input) async {
    final parsed = parsePublish(input.toJson());
    return parseCreated(await _rpc('publicar', {
      'p_intent': parsed.intent,
      'p_help_type': parsed.helpType,
      'p_title': parsed.title,
      'p_description': parsed.description,
      'p_area_label': parsed.areaLabel,
      'p_lat': parsed.lat,
      'p_lng': parsed.lng,
      'p_client_request_id': parsed.clientRequestId,
    }));
  }

  @override
  Future<CreatedRef> coordinate(String anuncioId, String clientRequestId) async {
    return parseCreated(await _rpc('coordinar', {
      'p_anuncio_id': anuncioId,
      'p_client_request_id': clientRequestId,
    }));
  }

  @override
  Future<void> requestEntry(String casoId) => _rpc('pedir_entrada', {'p_caso_id': casoId});

  @override
  Future<void> accept(String casoId, String userId) =>
      _rpc('aceptar_miembro', {'p_caso_id': casoId, 'p_user_id': userId});

  @override
  Future<void> reject(String casoId, String userId) =>
      _rpc('rechazar_miembro', {'p_caso_id': casoId, 'p_user_id': userId});

  @override
  Future<void> joinGroup(String casoId) => _rpc('unirme', {'p_caso_id': casoId});

  @override
  Future<void> removeMember(String casoId, String userId) =>
      _rpc('retirar_miembro', {'p_caso_id': casoId, 'p_user_id': userId});

  @override
  Future<void> resolve(String casoId) => _rpc('resolver_caso', {'p_caso_id': casoId});

  @override
  Future<void> cancel(String id) => _rpc('cancelar_publicacion', {'p_id': id});

  @override
  Future<void> reopen(String casoId) => _rpc('reabrir_caso', {'p_caso_id': casoId});

  @override
  Future<void> editAnuncio(String id, String title, String description) async {
    final text = parseAnnouncement(title, description);
    await _rpc('editar_anuncio', {'p_id': id, 'p_title': text.title, 'p_description': text.description});
  }

  @override
  Future<void> sendMessage(String casoId, String body) =>
      _rpc('enviar_mensaje', {'p_caso_id': casoId, 'p_body': parseMessage(body)});

  @override
  Future<void> recommend(String anuncioId) => _rpc('recomendar', {'p_anuncio_id': anuncioId});

  @override
  Future<void> rate(String casoId, int score, String comment) => _rpc('valorar', {
        'p_caso_id': casoId,
        'p_score': parseScore(score),
        'p_comment': parseComment(comment),
      });

  @override
  Future<void> report(String targetType, String targetId, String reason) => _rpc('reportar', {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_reason': parseReason(reason),
      });

  @override
  Future<void> block(String userId) => _rpc('bloquear', {'p_user_id': userId});

  @override
  Future<void> unblock(String userId) => _rpc('desbloquear', {'p_user_id': userId});

  @override
  Future<List<BlockView>> blocks() async => parseBlocks(await _rpc('listar_bloqueos'));

  @override
  Future<void> sharePhone(String casoId, String phone) =>
      _rpc('compartir_telefono', {'p_caso_id': casoId, 'p_phone': parsePhone(phone)});

  @override
  Future<int> pendingPublishes() async => 0;

  @override
  Future<int> flushPublishes() async => 0;

  @override
  Future<int> pendingMessages() async => 0;

  @override
  Future<int> flushMessages() async => 0;

  @override
  void Function() subscribeMessages(String casoId, void Function() onChange) {
    final channel = _client.channel('mensajes:$casoId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'publicacion_id',
            value: casoId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return () {
      _client.removeChannel(channel);
    };
  }

  @override
  void Function() watchSession(void Function() onChange) {
    final sub = _client.auth.onAuthStateChange.listen((_) => onChange());
    return () {
      sub.cancel();
    };
  }
}
