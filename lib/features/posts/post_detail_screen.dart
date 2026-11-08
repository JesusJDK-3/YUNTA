import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_catalog.dart';
import 'post_chat_screen.dart';
import 'post_detail_widgets.dart';
import 'post_edit_dialog.dart';
import 'post_interaction_actions.dart';
import 'post_image_preview.dart';
import 'post_repository.dart';
import 'post_rating_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final PostRepository _repository;
  Map<String, dynamic>? _post;
  String? _error;
  bool _loading = true;
  bool _working = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isAuthor => _post?['author_id'] == _userId;
  String get _status => _post?['status'] as String? ?? '';
  String get _membership => _post?['my_membership'] as String? ?? '';
  bool get _group => _post?['coordination_mode'] == 'group';
  bool get _canChat =>
      _status != 'cancelled' &&
      ((_isAuthor && _status != 'open') ||
          (!_isAuthor &&
              (_membership == 'accepted' || _membership == 'active')));
  bool get _canAcceptOffers => _status == 'open' || _status == 'coordinating';
  bool get _canRate {
    final provider = _post?['provider_name'] as String?;
    return _status == 'resolved' &&
        !_group &&
        provider != null &&
        provider.trim().isNotEmpty &&
        _post?['my_rating'] == null;
  }

  @override
  void initState() {
    super.initState();
    _repository = PostRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final post = await _repository.loadDetail(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo abrir el aviso. Actualiza e inténtalo de nuevo.';
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    setState(() => _working = true);
    try {
      final result = await _repository.join(widget.postId);
      if (!mounted) return;
      await _load();
      if (result == 'active' && mounted) await _openChat();
      if (result == 'pending' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu ofrecimiento quedó pendiente de confirmación.'),
          ),
        );
      }
    } catch (_) {
      _showError('No se pudo unir al aviso. Actualiza e inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _accept(String userId) async {
    setState(() => _working = true);
    try {
      await _repository.acceptOffer(widget.postId, userId);
      await _load();
      if (mounted) await _openChat();
    } catch (_) {
      _showError('No se pudo aceptar este ofrecimiento. Actualiza el aviso.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _recommend() async {
    setState(() => _working = true);
    try {
      await _repository.recommend(widget.postId);
      await _load();
    } catch (_) {
      _showError('No se pudo guardar la recomendación.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editAd() async {
    final post = _post!;
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => PostEditDialog(
        title: post['title'] as String? ?? '',
        description: post['description'] as String? ?? '',
        onSave: (title, description) => _repository.editLocalAd(
          id: widget.postId,
          title: title,
          description: description,
          areaLabel: post['area_label'] as String? ?? 'Zona aproximada',
        ),
      ),
    );
    if (updated == true && mounted) await _load();
  }

  Future<void> _openChat() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PostChatScreen(
          postId: widget.postId,
          title: _post?['title'] as String? ?? 'Coordinación vecinal',
          readOnly: _status == 'resolved',
          statusLabel: postStatusLabel(_status),
          group: _group,
        ),
      ),
    );
  }

  Future<void> _openRating() async {
    final provider = _post?['provider_name'] as String?;
    if (!_canRate || provider == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostRatingScreen(
          postId: widget.postId,
          title: _post?['title'] as String? ?? '',
          providerName: provider,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeStatus(String action) async {
    setState(() => _working = true);
    try {
      if (action == 'resolve') {
        await _repository.resolve(widget.postId);
      } else if (action == 'cancel') {
        await _repository.cancel(widget.postId);
      } else if (action == 'reopen') {
        await _repository.reopen(widget.postId);
      }
      await _load();
      if (action == 'resolve' && _canRate && mounted) await _openRating();
    } catch (_) {
      _showError('No se pudo actualizar el aviso. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar aviso'),
        content: const Text('Los vecinos ya no podrán unirse a este caso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _changeStatus('cancel');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del aviso')),
    bottomNavigationBar: _visitorBar(),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _errorView()
        : _postView(context),
  );

  Widget? _visitorBar() {
    if (_post == null || _isAuthor || (!_canChat && !_canAcceptOffers)) {
      return null;
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: const BoxDecoration(
          color: YuntaColors.surfaceWhite,
          border: Border(top: BorderSide(color: YuntaColors.outlineSoft)),
        ),
        child: PostInteractionActions(
          isAuthor: false,
          canChat: _canChat,
          group: _group,
          status: _status,
          membership: _membership,
          type: _post?['type'] as String? ?? '',
          localAd: _post?['category'] == 'products_services',
          working: _working,
          onOpenChat: _openChat,
          onJoin: _join,
          onResolve: () => _changeStatus('resolve'),
          onCancel: _confirmCancel,
          onReopen: () => _changeStatus('reopen'),
          onEdit: _editAd,
        ),
      ),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() {
              _loading = true;
              _load();
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );

  Widget _postView(BuildContext context) {
    final post = _post!;
    final type = postTypeFor(post['type'] as String? ?? '');
    final offers = (post['offers'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final distance = (post['distance_m'] as num?)?.round();
    final locationLabel = distance == null ? '' : 'A $distance m';
    final emergency = post['category'] == 'emergency';
    final active = _status == 'open' || _status == 'coordinating';
    final recommendationCount =
        (post['recommendation_count'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        PostDetailSummaryCard(
          icon: type?.icon ?? Icons.campaign_outlined,
          typeLabel: type?.publishLabel ?? type?.label ?? 'Aviso vecinal',
          mode: _group ? 'Grupal' : 'Individual',
          title: post['title'] as String? ?? '',
          author: post['author_name'] as String? ?? 'Vecino',
          locationLabel: locationLabel,
          statusLabel: postStatusLabel(_status),
          statusColor: active ? YuntaColors.success : YuntaColors.muted,
          memberCount: (post['member_count'] as num?)?.toInt() ?? 0,
          description: post['description'] as String? ?? '',
          emergency: emergency,
        ),
        if (post['image_url'] is String &&
            (post['image_url'] as String).isNotEmpty) ...[
          const SizedBox(height: 16),
          PostImagePreview(url: post['image_url'] as String),
        ],
        if (emergency) const PostEmergencyNote(),
        if (_canRate) ...[
          const SizedBox(height: 16),
          _ratingCard(post['provider_name'] as String),
        ],
        if (_isAuthor && offers.isNotEmpty && _canAcceptOffers) ...[
          const SizedBox(height: 26),
          Text(
            'Vecinos que quieren ayudar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final offer in offers)
            PostOfferTile(
              offer: offer,
              onAccept: _working
                  ? null
                  : () => _accept(offer['user_id'] as String),
            ),
        ],
        if (post['category'] == 'products_services' && active) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _working || _isAuthor || post['has_recommended'] == true
                ? null
                : _recommend,
            icon: const Icon(Icons.thumb_up_alt_outlined),
            label: Text(
              post['has_recommended'] == true
                  ? 'Ya recomendaste este aviso'
                  : 'Recomendar · $recommendationCount',
            ),
          ),
        ],
        if (_isAuthor) ...[
          const SizedBox(height: 20),
          PostInteractionActions(
            isAuthor: true,
            canChat: _canChat,
            group: _group,
            status: _status,
            membership: _membership,
            type: post['type'] as String? ?? '',
            localAd: post['category'] == 'products_services',
            working: _working,
            onOpenChat: _openChat,
            onJoin: _join,
            onResolve: () => _changeStatus('resolve'),
            onCancel: _confirmCancel,
            onReopen: () => _changeStatus('reopen'),
            onEdit: _editAd,
          ),
        ],
      ],
    );
  }

  Widget _ratingCard(String provider) => Card(
    color: YuntaColors.surfaceMint,
    child: ListTile(
      leading: const Icon(
        Icons.star_outline_rounded,
        color: YuntaColors.primary,
      ),
      title: const Text('¿Cómo fue la ayuda?'),
      subtitle: Text('Valora tu experiencia con $provider.'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: _working ? null : _openRating,
    ),
  );
}
