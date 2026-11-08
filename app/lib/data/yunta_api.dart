import '../domain/models.dart';

/// Contrato único de la app.
/// Cada método llama una función de Supabase. Ninguno devuelve latitud ni longitud.
abstract class YuntaApi {
  Future<List<ZoneOption>> listZones();
  Future<Session?> currentSession();

  /// Correo ya autenticado que todavía no eligió zona.
  Future<String?> pendingEmail();
  Future<void> requestMagicLink(String email);
  Future<Session> saveProfile(String displayName, String zoneId);
  Future<void> signOut();
  Future<FeedResult> feed(String tab, ViewerPoint? point);
  Future<Detail> detail(String id);
  Future<CreatedRef> publish(PublishInput input);
  Future<CreatedRef> coordinate(String anuncioId, String clientRequestId);
  Future<void> requestEntry(String casoId);
  Future<void> accept(String casoId, String userId);
  Future<void> reject(String casoId, String userId);
  Future<void> joinGroup(String casoId);
  Future<void> removeMember(String casoId, String userId);
  Future<void> resolve(String casoId);
  Future<void> cancel(String id);
  Future<void> reopen(String casoId);
  Future<void> editAnuncio(String id, String title, String description);
  Future<void> sendMessage(String casoId, String body);
  Future<void> recommend(String anuncioId);
  Future<void> rate(String casoId, int score, String comment);
  Future<void> report(String targetType, String targetId, String reason);
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Future<List<BlockView>> blocks();
  Future<void> sharePhone(String casoId, String phone);
  Future<int> pendingPublishes();
  Future<int> flushPublishes();
  Future<int> pendingMessages();
  Future<int> flushMessages();

  /// Avisa cuando entra un mensaje. Devuelve la función que cancela la escucha.
  void Function() subscribeMessages(String casoId, void Function() onChange);

  /// Avisa cuando la sesión de Supabase cambia (vuelta del enlace al correo).
  void Function() watchSession(void Function() onChange);
}
