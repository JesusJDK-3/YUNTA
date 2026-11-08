import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepository {
  const PostRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> loadNearby() async {
    final result = await _client.rpc(
      'nearby_posts',
      params: {'p_category': null},
    );
    return (result as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<void> createPost({
    required String id,
    required String category,
    required String type,
    required String title,
    required String description,
    required String coordinationMode,
    required double latitude,
    required double longitude,
  }) async {
    await _client.rpc(
      'create_post',
      params: {
        'p_id': id,
        'p_category': category,
        'p_type': type,
        'p_title': title.trim(),
        'p_description': description.trim(),
        'p_mode': coordinationMode,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_area_label': 'Zona aproximada',
      },
    );
  }
}
