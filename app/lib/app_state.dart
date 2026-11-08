import 'package:flutter/foundation.dart';

import 'data/key_value.dart';
import 'data/yunta_api.dart';
import 'domain/boards.dart';
import 'domain/models.dart';
import 'domain/yunta_exception.dart';
import 'place.dart';

enum PlaceStatus { idle, loading, ready, denied }

/// Estado de la sesión y del punto.
/// El punto no se persiste: al cerrar el proceso se olvida.
class AppState extends ChangeNotifier {
  AppState(this.api, this.store);

  final YuntaApi api;
  final KeyValue store;

  Session? session;
  String? pendingEmail;
  String? notice;
  ViewerPoint? point;
  PlaceStatus placeStatus = PlaceStatus.idle;
  bool booting = true;
  bool showTutorial = false;

  static const _tutorialKey = 'yunta.tutorial.v1';

  Future<void> refresh() async {
    try {
      final sessionFuture = api.currentSession();
      final emailFuture = api.pendingEmail();
      final postsFuture = api.flushPublishes();
      final messagesFuture = api.flushMessages();
      final nextSession = await sessionFuture;
      final email = await emailFuture;
      final posts = await postsFuture;
      final messages = await messagesFuture;
      session = nextSession;
      pendingEmail = email;
      final sent = sentNotice(posts, messages);
      if (sent != null) notice = sent;
      if (nextSession != null && store.getString(_tutorialKey) != 'done') {
        showTutorial = true;
      }
    } catch (error) {
      notice = asYunta(error).text;
    } finally {
      booting = false;
      notifyListeners();
    }
  }

  Future<void> askPlace() async {
    if (placeStatus == PlaceStatus.loading) return;
    placeStatus = PlaceStatus.loading;
    notifyListeners();
    final next = await readPlace();
    point = next;
    placeStatus = next == null ? PlaceStatus.denied : PlaceStatus.ready;
    notifyListeners();
  }

  void setSession(Session? next) {
    session = next;
    if (next != null && store.getString(_tutorialKey) != 'done') showTutorial = true;
    notifyListeners();
  }

  Future<void> finishTutorial() async {
    await store.setString(_tutorialKey, 'done');
    showTutorial = false;
    notifyListeners();
  }

  void clearNotice() {
    notice = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await api.signOut();
    session = null;
    pendingEmail = null;
    point = null;
    placeStatus = PlaceStatus.idle;
    notifyListeners();
  }
}
