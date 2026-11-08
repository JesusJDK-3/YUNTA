import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/yunta_wordmark.dart';
import '../auth/profile_repository.dart';
import '../posts/post_card.dart';
import '../posts/post_catalog.dart';
import '../posts/post_composer_screen.dart';
import '../posts/post_repository.dart';
import '../posts/post_type_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.profile, super.key});

  final RegisteredProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PostRepository _postsRepository;
  final List<Map<String, dynamic>> _posts = [];
  PostCategory _category = PostCategory.help;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _postsRepository = PostRepository(Supabase.instance.client);
    _loadPosts();
  }

  Future<void> _loadPosts({bool showLoader = false}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final posts = await _postsRepository.loadNearby();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los avisos. Revisa tu conexión.';
        _loading = false;
      });
    }
  }

  Future<void> _publish() async {
    final type = await showPostTypeSheet(context);
    if (type == null || !mounted) return;
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostComposerScreen(
          type: type,
          initialLocation: widget.profile.location,
        ),
      ),
    );
    if (published != true || !mounted) return;
    setState(() => _category = type.category);
    await _loadPosts(showLoader: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso publicado en Yunta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = _posts
        .where((post) => post['category'] == _category.databaseValue)
        .toList(growable: false);
    final emergencyCount = _posts
        .where((post) => post['category'] == 'emergency')
        .length;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publish,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publicar'),
        backgroundColor: YuntaColors.yellow,
        foregroundColor: YuntaColors.inkStrong,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: () => _loadPosts(showLoader: true),
              color: YuntaColors.ink,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                children: [
                  _brandRow(),
                  const SizedBox(height: 34),
                  Text(
                    'Cerca de ti',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const _RadiusPill(),
                  const SizedBox(height: 24),
                  Text(
                    'Hola, ${widget.profile.displayName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 22),
                  _categorySelector(),
                  if (emergencyCount > 0 && _category != PostCategory.emergency)
                    _emergencyBanner(emergencyCount),
                  const SizedBox(height: 18),
                  Text(
                    _category == PostCategory.help
                        ? 'Ayuda vecinal'
                        : _category.label,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 42),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _loadError()
                  else if (visiblePosts.isEmpty)
                    _emptyState(context)
                  else
                    for (final post in visiblePosts) ...[
                      PostCard(post: post),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const YuntaWordmark(compact: true),
      Semantics(
        label: 'Perfil de ${widget.profile.displayName}',
        child: CircleAvatar(
          radius: 24,
          backgroundColor: YuntaColors.yellow,
          child: Text(
            widget.profile.displayName.characters.first.toUpperCase(),
            style: const TextStyle(
              color: YuntaColors.inkStrong,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _categorySelector() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final category in PostCategory.values) ...[
          ChoiceChip(
            selected: _category == category,
            avatar: Icon(
              category.icon,
              size: 19,
              color: category == PostCategory.emergency
                  ? YuntaColors.danger
                  : YuntaColors.ink,
            ),
            label: Text(category.label),
            onSelected: (_) => setState(() => _category = category),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );

  Widget _emergencyBanner(int count) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: OutlinedButton.icon(
      onPressed: () => setState(() => _category = PostCategory.emergency),
      icon: const Icon(Icons.warning_amber_rounded),
      label: Text(
        '$count ${count == 1 ? 'aviso' : 'avisos'} de emergencia cerca',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: YuntaColors.danger,
        side: const BorderSide(color: YuntaColors.danger),
      ),
    ),
  );

  Widget _loadError() => Column(
    children: [
      const SizedBox(height: 32),
      const Icon(Icons.cloud_off_outlined, size: 40, color: YuntaColors.muted),
      const SizedBox(height: 10),
      Text(_error!, textAlign: TextAlign.center),
      TextButton.icon(
        onPressed: () => _loadPosts(showLoader: true),
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
    ],
  );

  Widget _emptyState(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 10),
    child: Column(
      children: [
        Icon(
          _category.icon,
          size: 42,
          color: YuntaColors.ink.withValues(alpha: .65),
        ),
        const SizedBox(height: 14),
        Text(
          'Aún no hay avisos de ${_category.label.toLowerCase()} cerca.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Publica una solicitud o comparte algo que pueda ayudar a un vecino.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _RadiusPill extends StatelessWidget {
  const _RadiusPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      border: Border.all(color: YuntaColors.outline, width: 1.4),
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_outlined, color: YuntaColors.ink),
        SizedBox(width: 7),
        Text('Radio de 500 m', style: TextStyle(color: YuntaColors.ink)),
      ],
    ),
  );
}
