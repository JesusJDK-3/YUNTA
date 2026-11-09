import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import '../posts/post_catalog.dart';
import '../posts/post_chat_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/post_repository.dart';
import '../posts/post_rating_screen.dart';
import '../posts/post_rating_eligibility.dart';

class HomeCasesScreen extends StatefulWidget {
  const HomeCasesScreen({super.key});

  @override
  State<HomeCasesScreen> createState() => _HomeCasesScreenState();
}

class _HomeCasesScreenState extends State<HomeCasesScreen> {
  late final PostRepository _repository;
  late Future<List<Map<String, dynamic>>> _cases;

  @override
  void initState() {
    super.initState();
    _repository = PostRepository(Supabase.instance.client);
    _cases = _repository.loadMyCases();
  }

  Future<void> _refresh() async {
    final request = _repository.loadMyCases();
    setState(() => _cases = request);
    await request;
  }

  Future<void> _openChat(Map<String, dynamic> item) async {
    final postId = item['post_id'] as String;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PostChatScreen(
          postId: postId,
          title: item['title'] as String,
          onCaseResolved: () => _promptRating(postId),
          onOpenDetails: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: postId),
              ),
            );
          },
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _promptRating(String postId) async {
    try {
      final detail = await _repository.loadDetail(postId);
      final provider = detail['provider_name'] as String?;
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (!mounted ||
          detail['can_rate'] != true ||
          !isExpectedPostRater(detail, currentUserId ?? '') ||
          detail['status'] != 'resolved' ||
          detail['coordination_mode'] == 'group' ||
          detail['my_rating'] != null ||
          provider == null ||
          provider.trim().isEmpty) {
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PostRatingScreen(
            postId: postId,
            title: detail['title'] as String? ?? '',
            providerName: provider,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la valoración.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Casos')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _cases,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _CaseMessage(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar tus casos',
            action: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          );
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const _CaseMessage(
            icon: Icons.forum_outlined,
            title: 'Aún no tienes casos en coordinación',
            detail:
                'Cuando acepten tu ayuda o alguien se una a un caso, '
                'la conversación aparecerá aquí.',
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CaseTile(
              item: rows[index],
              onTap: () => _openChat(rows[index]),
            ),
          ),
        );
      },
    ),
  );
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = postTypeFor(item['type'] as String? ?? '');
    final preview = item['last_message'] as String?;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        minVerticalPadding: 14,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: YuntaColors.surfaceMint,
          child: Icon(
            type?.icon ?? Icons.forum_outlined,
            color: YuntaColors.primary,
          ),
        ),
        title: Text(
          item['title'] as String? ?? 'Caso vecinal',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          preview?.isNotEmpty == true ? preview! : 'Chat de coordinación',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _CaseMessage extends StatelessWidget {
  const _CaseMessage({
    required this.icon,
    required this.title,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: YuntaColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (detail case final message?)
            Text(message, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
