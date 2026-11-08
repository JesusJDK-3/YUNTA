import 'package:flutter_test/flutter_test.dart';
import 'package:yunta/data/key_value.dart';
import 'package:yunta/data/offline_yunta.dart';
import 'package:yunta/data/yunta_api.dart';
import 'package:yunta/domain/models.dart';
import 'package:yunta/domain/yunta_exception.dart';

class _Fake implements YuntaApi {
  _Fake({required this.session, required this.feedResult, required this.detailResult});

  bool online = true;
  final Session session;
  final FeedResult feedResult;
  final Detail detailResult;
  final List<String> sent = [];

  Never _down() => throw const YuntaException('network');

  @override
  Future<Session?> currentSession() async => online ? session : _down();

  @override
  Future<FeedResult> feed(String tab, ViewerPoint? point) async => online ? feedResult : _down();

  @override
  Future<Detail> detail(String id) async => online ? detailResult : _down();

  @override
  Future<void> sendMessage(String casoId, String body) async {
    if (!online) _down();
    sent.add(body);
  }

  @override
  Future<List<ZoneOption>> listZones() async => kZones;
  @override
  Future<String?> pendingEmail() async => null;
  @override
  Future<void> requestMagicLink(String email) async {}
  @override
  Future<Session> saveProfile(String displayName, String zoneId) async => session;
  @override
  Future<void> signOut() async {}
  @override
  Future<CreatedRef> publish(PublishInput input) async => const CreatedRef(id: 'x', deduped: false);
  @override
  Future<CreatedRef> coordinate(String anuncioId, String clientRequestId) async => const CreatedRef(id: 'x', deduped: false);
  @override
  Future<void> requestEntry(String casoId) async {}
  @override
  Future<void> accept(String casoId, String userId) async {}
  @override
  Future<void> reject(String casoId, String userId) async {}
  @override
  Future<void> joinGroup(String casoId) async {}
  @override
  Future<void> removeMember(String casoId, String userId) async {}
  @override
  Future<void> resolve(String casoId) async {}
  @override
  Future<void> cancel(String id) async {}
  @override
  Future<void> reopen(String casoId) async {}
  @override
  Future<void> editAnuncio(String id, String title, String description) async {}
  @override
  Future<void> recommend(String anuncioId) async {}
  @override
  Future<void> rate(String casoId, int score, String comment) async {}
  @override
  Future<void> report(String targetType, String targetId, String reason) async {}
  @override
  Future<void> block(String userId) async {}
  @override
  Future<void> unblock(String userId) async {}
  @override
  Future<List<BlockView>> blocks() async => const [];
  @override
  Future<void> sharePhone(String casoId, String phone) async {}
  @override
  Future<int> pendingPublishes() async => 0;
  @override
  Future<int> flushPublishes() async => 0;
  @override
  Future<int> pendingMessages() async => 0;
  @override
  Future<int> flushMessages() async => 0;
  @override
  void Function() subscribeMessages(String casoId, void Function() onChange) => () {};
  @override
  void Function() watchSession(void Function() onChange) => () {};
}

void main() {
  test('relee el muro y deja el mensaje en cola cuando no hay red', () async {
    final item = FeedItem(
      id: '22222222-2222-4222-8222-222222222222',
      kind: 'caso',
      category: 'ayuda',
      type: 'herramienta',
      title: 'Muleta',
      description: 'Para una semana',
      zoneId: 'centro',
      zoneName: 'Zona Centro',
      areaLabel: 'Zona Centro',
      distanceLabel: null,
      coordinationMode: 'individual',
      status: 'abierto',
      recommendationCount: 0,
      ratingAverage: null,
      ratingCount: 0,
      authorId: '11111111-1111-4111-8111-111111111111',
      authorName: 'Ana',
      sourceAnuncioId: null,
      createdAt: '2026-11-08T00:00:00.000Z',
    );
    final fake = _Fake(
      session: Session(userId: item.authorId, displayName: 'Ana', zoneId: 'centro', zoneName: 'Zona Centro'),
      feedResult: FeedResult(items: [item], needsLocation: false),
      detailResult: Detail(
        item: item,
        members: const [],
        pending: const [],
        messages: const [],
        myRole: 'receptor',
        myStatus: 'aceptado',
        isAuthor: true,
        chatOpen: true,
        canSend: true,
        canRecommend: false,
        alreadyRecommended: false,
        canOfferHelp: false,
        canRequestHelp: false,
        canJoinGroup: false,
        canResolve: false,
        canCancel: false,
        canReopen: false,
        canSharePhone: false,
        canEdit: false,
        canRetire: false,
        canRate: false,
        myRating: null,
      ),
    );
    final api = OfflineYunta(fake, MemoryStore());

    expect((await api.feed('ayuda', null)).offline, isFalse);
    await api.detail(item.id);
    fake.online = false;

    final cached = await api.feed('ayuda', null);
    expect(cached.offline, isTrue);
    expect(cached.items.first.title, 'Muleta');
    await expectLater(api.feed('emergencias', null), throwsA(isA<YuntaException>()));

    await api.sendMessage(item.id, 'Sigo aquí');
    final ficha = await api.detail(item.id);
    expect(ficha.offline, isTrue);
    expect(ficha.messages.map((row) => row.body), ['Sigo aquí']);
    expect(ficha.messages.first.pending, isTrue);

    fake.online = true;
    expect(await api.flushMessages(), 1);
    expect(fake.sent, ['Sigo aquí']);
    expect(await api.pendingMessages(), 0);
  });
}
