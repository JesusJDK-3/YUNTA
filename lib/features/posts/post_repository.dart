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

  Future<Map<String, dynamic>> loadDetail(String id) async {
    final result = await _client.rpc(
      'get_post_detail',
      params: {'p_post_id': id},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<String> join(String id) async =>
      await _client.rpc('join_post', params: {'p_post_id': id}) as String;

  Future<void> acceptOffer(String postId, String userId) async {
    await _client.rpc(
      'accept_post_offer',
      params: {'p_post_id': postId, 'p_user_id': userId},
    );
  }

  Future<void> recommend(String id) async {
    await _client.rpc('recommend_ad', params: {'p_post_id': id});
  }

  Future<void> resolve(String id) async {
    await _client.rpc('resolve_post', params: {'p_post_id': id});
  }

  Future<void> cancel(String id) async {
    await _client.rpc('cancel_post', params: {'p_post_id': id});
  }

  Future<void> reopen(String id) async {
    await _client.rpc('reopen_post', params: {'p_post_id': id});
  }

  Future<void> editLocalAd({
    required String id,
    required String title,
    required String description,
    required String areaLabel,
  }) async {
    await _client.rpc(
      'edit_local_ad',
      params: {
        'p_post_id': id,
        'p_title': title.trim(),
        'p_description': description.trim(),
        'p_area_label': areaLabel,
      },
    );
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
