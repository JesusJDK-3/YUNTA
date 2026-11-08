import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yunta/app/yunta_app.dart';
import 'package:yunta/features/posts/pending_post_store.dart';
import 'package:yunta/features/posts/post_catalog.dart';

void main() {
  testWidgets('sin claves muestra cómo conectar', (tester) async {
    await tester.pumpWidget(const YuntaApp(supabaseConfigured: false));
    expect(find.text('Falta conectar Yunta'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('la hoja deja publicar los siete tipos del reto', () {
    expect(publishablePostTypes, hasLength(7));
    final urgent = publishablePostTypes.singleWhere(
      (type) => type.value == 'urgent_request',
    );
    final support = publishablePostTypes.singleWhere(
      (type) => type.value == 'support_group_available',
    );
    expect(urgent.groupOnly, isFalse);
    expect(support.groupOnly, isTrue);
  });

  test('un aviso pendiente conserva el mismo identificador', () async {
    final folder = await Directory.systemTemp.createTemp('yunta-pending');
    final store = PendingPostStore(directory: folder);
    const post = PendingPost(
      id: '6b1d4c2a-7e8f-4a1b-9c3d-0e5f6a7b8c9d',
      category: 'help',
      type: 'help_offer',
      title: 'Puedo ayudar',
      description: 'Tengo una muleta disponible hoy.',
      coordinationMode: 'individual',
      latitude: -12.0464,
      longitude: -77.0428,
      createdAt: '2026-11-08T20:00:00Z',
    );
    await store.upsert(post);
    final saved = await store.read();
    expect(saved.single.id, post.id);
    expect(PendingPost.fromJson(post.toJson())?.id, post.id);
    await store.remove(post.id);
    expect(await store.read(), isEmpty);
    await folder.delete(recursive: true);
  });
}
