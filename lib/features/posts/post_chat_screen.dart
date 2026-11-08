import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';

class PostChatScreen extends StatefulWidget {
  const PostChatScreen({
    required this.postId,
    required this.title,
    this.readOnly = false,
    super.key,
  });

  final String postId;
  final String title;
  final bool readOnly;

  @override
  State<PostChatScreen> createState() => _PostChatScreenState();
}

class _PostChatScreenState extends State<PostChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _messages;
  String? _latestRenderedId;
  bool _sending = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _messages = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    final userId = _userId;
    if (body.isEmpty || userId.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('messages').insert({
        'post_id': widget.postId,
        'sender_id': userId,
        'body': body,
      });
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar. Revisa tu conexión e inténtalo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(30),
        child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Chat privado de este aviso'),
        ),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messages,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se pudo cargar el chat. Actualiza el aviso.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snapshot.data!;
              if (rows.isNotEmpty) _scrollToNewest(rows);
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Este chat está listo. Coordinen aquí sin compartir '
                      'datos privados en el muro.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final message = rows[index];
                  return _MessageBubble(
                    body: message['body'] as String? ?? '',
                    mine: message['sender_id'] == _userId,
                  );
                },
              );
            },
          ),
        ),
        if (widget.readOnly)
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Caso resuelto · chat disponible para consulta'),
            ),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje…',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    tooltip: 'Enviar mensaje',
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.body, required this.mine});

  final String body;
  final bool mine;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? YuntaColors.action : YuntaColors.surfaceWhite,
        borderRadius: BorderRadius.circular(17),
        border: mine
            ? null
            : Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .55)),
      ),
      child: Text(
        body,
        style: TextStyle(color: mine ? YuntaColors.inkStrong : YuntaColors.ink),
      ),
    ),
  );
}
