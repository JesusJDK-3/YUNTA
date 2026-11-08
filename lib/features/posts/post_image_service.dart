import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'post_image_sanitizer.dart';

class PostImageService {
  const PostImageService(this._client);

  static const bucket = 'yunta-post-images';
  static const maxBytes = 5 * 1024 * 1024;
  final SupabaseClient _client;

  Future<void> attachToPost(String postId, XFile image) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const FormatException('Sesión no disponible.');
    final source = await image.readAsBytes();
    final bytes = await compute(sanitizePostImage, source);
    if (bytes.length > maxBytes) {
      throw const FormatException('La foto no puede superar 5 MB.');
    }
    final path = '$userId/$postId/${const Uuid().v4()}.jpg';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    try {
      await _client.from('post_images').insert({
        'post_id': postId,
        'author_id': userId,
        'storage_path': path,
      });
    } catch (_) {
      try {
        await _client.storage.from(bucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<Map<String, String>> signedUrlsFor(List<String> postIds) async {
    if (postIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('post_images')
          .select('post_id, storage_path')
          .inFilter('post_id', postIds);
      final paths = <String, String>{
        for (final row in rows)
          row['post_id'] as String: row['storage_path'] as String,
      };
      final entries = await Future.wait(
        paths.entries.map((entry) async {
          try {
            final url = await _client.storage
                .from(bucket)
                .createSignedUrl(entry.value, 1800);
            return MapEntry(entry.key, url);
          } catch (_) {
            return null;
          }
        }),
      );
      return Map.fromEntries(entries.whereType<MapEntry<String, String>>());
    } catch (_) {
      return {};
    }
  }

}
