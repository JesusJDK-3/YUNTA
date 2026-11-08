import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  const NotificationRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> watchMine() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> markRead(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('recipient_id', userId);
  }
}
