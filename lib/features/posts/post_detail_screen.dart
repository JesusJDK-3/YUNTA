import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_catalog.dart';
import 'post_chat_screen.dart';
import 'post_detail_widgets.dart';
import 'post_edit_dialog.dart';
import 'post_interaction_actions.dart';
import 'post_repository.dart';

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
        ),
      ),
    );
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
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _errorView()
        : _postView(context),
  );

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
    final area = post['area_label'] as String?;
    final hasArea =
        area != null &&
        area.trim().isNotEmpty &&
        area.trim().toLowerCase() != 'zona aproximada';
    final emergency = post['category'] == 'emergency';
    final active = _status == 'open' || _status == 'coordinating';
    final recommendationCount =
        (post['recommendation_count'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Row(
          children: [
            Icon(
              type?.icon ?? Icons.campaign_outlined,
              color: emergency ? YuntaColors.danger : YuntaColors.ink,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                type?.label ?? 'Aviso vecinal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: emergency ? YuntaColors.danger : YuntaColors.ink,
                ),
              ),
            ),
            Text(_group ? 'Grupal' : 'Individual'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          post['title'] as String? ?? '',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 9),
        Text('Publicado por ${post['author_name'] ?? 'Vecino'}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            PostDetailFact(
              icon: Icons.location_on_outlined,
              label: [
                if (hasArea) area.trim(),
                if (distance != null) 'A $distance m',
              ].join(' · '),
            ),
            PostDetailFact(
              icon: Icons.circle,
              label: postStatusLabel(_status),
              color: _status == 'open' || _status == 'coordinating'
                  ? const Color(0xFF368857)
                  : YuntaColors.muted,
            ),
            PostDetailFact(
              icon: Icons.groups_outlined,
              label: '${post['member_count'] ?? 0} participantes',
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          post['description'] as String? ?? '',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (emergency) const PostEmergencyNote(),
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
        const SizedBox(height: 20),
        PostInteractionActions(
          isAuthor: _isAuthor,
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
    );
  }
}
