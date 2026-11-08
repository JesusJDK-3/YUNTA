import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_chat_message_widgets.dart';
import 'post_chat_widgets.dart';
import 'post_repository.dart';

class PostChatScreen extends StatefulWidget {
  const PostChatScreen({
    required this.postId,
    required this.title,
    this.onOpenDetails,
    super.key,
  });

  final String postId;
  final String title;
  final VoidCallback? onOpenDetails;

  @override
  State<PostChatScreen> createState() => _PostChatScreenState();
}

class _PostChatScreenState extends State<PostChatScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final PostRepository _repository;
  Map<String, dynamic>? _chatDetails;
  late Stream<List<Map<String, dynamic>>> _messages;
  String? _activeChatId;
  final Set<String> _unknownSenders = {};
  Timer? _contextTimer;
  String? _latestRenderedId;
  int _contextRequestId = 0;
  bool _loadingContext = true;
  bool _contextUnavailable = false;
  bool _refreshingContext = false;
  bool _sending = false;
  bool _resolving = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _repository = PostRepository(client);
    WidgetsBinding.instance.addObserver(this);
    _refreshChatContext();
    _startContextPolling();
  }

  void _startContextPolling() {
    _contextTimer?.cancel();
    _contextTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshChatContext(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChatContext(force: true);
      _startContextPolling();
    } else {
      _contextTimer?.cancel();
      _contextTimer = null;
    }
  }

  Future<void> _refreshChatContext({bool force = false}) async {
    if (_refreshingContext && !force) return;
    _refreshingContext = true;
    final requestId = ++_contextRequestId;
    try {
      final details = await _repository.loadChatContext(widget.postId);
      if (!mounted || requestId != _contextRequestId) return;
      final chatId = details['chat_id'] as String?;
      if (chatId == null || chatId.isEmpty) {
        throw StateError('La conversación no tiene un identificador válido.');
      }
      _subscribeMessages(chatId);
      setState(() {
        _chatDetails = details;
        _loadingContext = false;
        _contextUnavailable = false;
      });
    } catch (_) {
      if (!mounted || requestId != _contextRequestId) return;
      setState(() {
        _loadingContext = false;
        _contextUnavailable = true;
      });
    } finally {
      if (requestId == _contextRequestId) _refreshingContext = false;
    }
  }

  void _retryContext() {
    setState(() => _loadingContext = true);
    _refreshChatContext(force: true);
  }

  void _subscribeMessages(String chatId, {bool force = false}) {
    if (_activeChatId == chatId && !force) return;
    _activeChatId = chatId;
    _latestRenderedId = null;
    _unknownSenders.clear();
    _messages = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('post_id', widget.postId)
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contextTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    final userId = _userId;
    final chatId = _activeChatId;
    if (body.isEmpty || userId.isEmpty || chatId == null || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('messages').insert({
        'post_id': widget.postId,
        'chat_id': chatId,
        'sender_id': userId,
        'body': body,
      });
      _controller.clear();
    } catch (_) {
      if (mounted) _showMessage('No se pudo enviar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _finishCase() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    try {
      await _repository.resolve(widget.postId);
      await _refreshChatContext(force: true);
      if (!mounted) return;
      _showMessage('Caso finalizado. El chat queda disponible para consulta.');
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo finalizar el caso. Inténtalo otra vez.');
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final details = _chatDetails;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat de coordinación', maxLines: 1)),
      body: _loadingContext
          ? const Center(child: CircularProgressIndicator())
          : _contextUnavailable || details == null
          ? ChatLoadState(
              message: 'No se pudo verificar el acceso y estado del caso.',
              onRetry: _retryContext,
            )
          : _buildConversation(details),
    );
  }

  Widget _buildConversation(Map<String, dynamic> details) {
    final status = details['status'] as String? ?? '';
    final group = details['coordination_mode'] == 'group';
    final resolved = status == 'resolved';
    final canFinish =
        details['is_author'] == true && status == 'coordinating' && !resolved;
    return Column(
      children: [
        ChatParticipantHeader(
          name: _peerName(details, group),
          subtitle: _participantSubtitle(details, group),
          group: group,
          onOpenDetails: widget.onOpenDetails,
        ),
        ChatCoordinationBanner(
          title: details['title'] as String? ?? widget.title,
          status: status,
          group: group,
          canFinish: canFinish,
          resolving: _resolving,
          onFinish: _finishCase,
        ),
        const ChatPrivacyNote(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messages,
            builder: (context, messageSnapshot) {
              if (messageSnapshot.hasError) {
                return ChatLoadState(
                  message: 'No se pudieron cargar los mensajes.',
                  onRetry: () {
                    final chatId = _activeChatId;
                    if (chatId != null) {
                      setState(() => _subscribeMessages(chatId, force: true));
                    }
                  },
                );
              }
              if (!messageSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = messageSnapshot.data!;
              final names = _participantNames(details);
              final unknownSenders = messages
                  .map((message) => message['sender_id'] as String? ?? '')
                  .where(
                    (sender) =>
                        sender.isNotEmpty &&
                        sender != _userId &&
                        !names.containsKey(sender) &&
                        !_unknownSenders.contains(sender),
                  )
                  .toSet();
              if (unknownSenders.isNotEmpty) {
                _unknownSenders.addAll(unknownSenders);
                _refreshChatContext();
              }
              if (messages.isNotEmpty) _scrollToNewest(messages);
              return ChatTimelineList(
                messages: messages,
                userId: _userId,
                participantNames: names,
                controller: _scrollController,
              );
            },
          ),
        ),
        if (resolved)
          const ChatReadOnlyNote()
        else
          _Composer(controller: _controller, sending: _sending, onSend: _send),
      ],
    );
  }

  String _peerName(Map<String, dynamic> details, bool group) {
    if (group) return 'Coordinación vecinal';
    final value = details['peer_name'] as String?;
    if (value?.trim().isNotEmpty == true) return value!;
    return details['author_name'] as String? ?? 'Chat del caso';
  }

  String _participantSubtitle(Map<String, dynamic> details, bool group) {
    final distance = (details['distance_m'] as num?)?.round();
    final members = (details['member_count'] as num?)?.toInt() ?? 0;
    if (group) {
      final count = members + 1;
      final people = '$count ${count == 1 ? 'participante' : 'participantes'}';
      return distance == null ? people : '$people · aviso a $distance m aprox.';
    }
    return distance == null
        ? 'Chat individual del caso'
        : 'A $distance m del aviso · distancia aproximada';
  }

  Map<String, String> _participantNames(Map<String, dynamic> details) {
    final rows = details['participants'] as List<dynamic>? ?? const [];
    final names = <String, String>{};
    for (final row in rows) {
      if (row is! Map) continue;
      final id = row['user_id']?.toString();
      final name = row['display_name']?.toString();
      if (id != null && name != null && name.trim().isNotEmpty) {
        names[id] = name;
      }
    }
    return names;
  }

  void _scrollToNewest(List<Map<String, dynamic>> rows) {
    final newestId = rows.last['id'] as String?;
    if (newestId == null || newestId == _latestRenderedId) return;
    final wasAtBottom =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            100;
    _latestRenderedId = newestId;
    if (!wasAtBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: const BoxDecoration(
        color: YuntaColors.surfaceWhite,
        border: Border(top: BorderSide(color: YuntaColors.outlineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              maxLength: 2000,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje…',
                counterText: '',
                filled: true,
                fillColor: YuntaColors.surfaceBlue,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 50,
            child: IconButton.filled(
              onPressed: sending ? null : onSend,
              tooltip: 'Enviar mensaje',
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}
