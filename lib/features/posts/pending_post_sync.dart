import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pending_post_store.dart';
import 'post_repository.dart';

class PendingPostSync {
  static Future<void> _tail = Future<void>.value();

  static Future<int> flush(SupabaseClient client) {
    final gate = _tail;
    final result = gate.then((_) => _sendAll(client));
    _tail = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  static Future<int> _sendAll(SupabaseClient client) async {
    final store = PendingPostStore.instance;
    final pending = await store.read();
    if (pending.isEmpty) return 0;
    final repository = PostRepository(client);
    var sent = 0;
    for (final post in pending) {
      if (post.blockedReason != null) continue;
      final published = await _publishOne(repository, store, post);
      if (published) sent += 1;
    }
    return sent;
  }

  static Future<bool> _publishOne(
    PostRepository repository,
    PendingPostStore store,
    PendingPost post,
  ) async {
    var created = false;
    try {
      await repository.createPost(
        id: post.id,
        category: post.category,
        type: post.type,
        title: post.title,
        description: post.description,
        coordinationMode: post.coordinationMode,
        latitude: post.latitude,
        longitude: post.longitude,
      );
      created = true;
      final imagePath = post.imagePath;
      if (imagePath != null && await File(imagePath).exists()) {
        await repository.attachImage(post.id, XFile(imagePath));
      }
      await store.remove(post.id);
      return true;
    } on PostgrestException catch (error) {
      if (created) {
        await store.remove(post.id);
        return true;
      }
      if (!_isPermanentRejection(error)) return false;
      await store.markBlocked(
        post.id,
        'El aviso no fue aceptado. Revisa el texto.',
      );
      return false;
    } catch (_) {
      return false;
    }
  }
}

bool _isPermanentRejection(PostgrestException error) {
  final code = error.code ?? '';
  return code == 'P0001' || code.startsWith('22') || code.startsWith('23');
}
