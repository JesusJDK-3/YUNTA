import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/yunta_navigation.dart';

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  bool _started = false;
  bool _listenersBound = false;

  Future<void> initializeForCurrentUser() async {
    final client = Supabase.instance.client;
    if (_started || client.auth.currentUser == null) return;
    _started = true;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _activateIfAllowed(messaging, settings.authorizationStatus);
    } catch (_) {
      _started = false;
      debugPrint('Yunta no pudo activar las notificaciones push.');
    }
  }

  Future<void> refreshAfterResume() async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        _started = false;
        return;
      }
      if (_started) return;
      await _activateIfAllowed(messaging, settings.authorizationStatus);
    } catch (_) {
      debugPrint('Yunta no pudo actualizar el permiso de notificaciones.');
    }
  }

  Future<void> _activateIfAllowed(
    FirebaseMessaging messaging,
    AuthorizationStatus status,
  ) async {
    if (status == AuthorizationStatus.denied ||
        status == AuthorizationStatus.notDetermined) {
      _started = false;
      return;
    }
    _bindListeners(messaging);
    await messaging.register();
    _started = true;
    if (await messaging.getInitialMessage() != null) _openInbox();
  }

  void _bindListeners(FirebaseMessaging messaging) {
    if (_listenersBound) return;
    _listenersBound = true;
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openInbox());
    messaging.onRegistered.listen(_saveFidSafely);
  }

  Future<void> _saveFid(String fid) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('push_tokens').upsert({
      'user_id': userId,
      'fid': fid,
      'platform': 'android',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'fid');
  }

  Future<void> _saveFidSafely(String fid) async {
    try {
      await _saveFid(fid);
    } catch (_) {
      debugPrint('Yunta no pudo registrar este dispositivo para push.');
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final body = message.notification?.body;
    if (body == null || body.isEmpty) return;
    yuntaMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(body),
        action: SnackBarAction(label: 'Ver', onPressed: _openInbox),
      ),
    );
  }

  void _openInbox() {
    yuntaNavigatorKey.currentState?.pushNamed('/notifications');
  }
}
