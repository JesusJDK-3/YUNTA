import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'post_image_service.dart';

class PostRepository {
  const PostRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> loadNearby() async {
    final result = await _client.rpc(
      'nearby_posts',
      params: {'p_category': null},
    );
    final posts = (result as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final imageUrls = await PostImageService(_client).signedUrlsFor(
      posts.map((post) => post['id'] as String).toList(growable: false),
    );
    return [
      for (final post in posts) {...post, 'image_url': imageUrls[post['id']]},
    ];
  }

  Future<Map<String, dynamic>> loadDetail(String id) async {
    final result = await _client.rpc(
      'get_post_detail',
      params: {'p_post_id': id},
    );
    final post = Map<String, dynamic>.from(result as Map);
    final imageUrls = await PostImageService(_client).signedUrlsFor([id]);
    return {...post, 'image_url': imageUrls[id]};
  }

  Future<void> attachImage(String postId, XFile image) =>
      PostImageService(_client).attachToPost(postId, image);

  Future<List<Map<String, dynamic>>> loadMyCases() async {
    final result = await _client.rpc('my_case_threads');
    return (result as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
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

  Future<void> rateProvider({
    required String postId,
    required int score,
    required String comment,
  }) async {
    await _client.rpc(
      'rate_provider',
      params: {
        'p_post_id': postId,
        'p_score': score,
        'p_comment': comment.trim().isEmpty ? null : comment.trim(),
      },
    );
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
