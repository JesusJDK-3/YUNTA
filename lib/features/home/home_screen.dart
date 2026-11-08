import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import '../auth/profile_repository.dart';
import '../notifications/push_notification_service.dart';
import '../posts/post_card.dart';
import '../posts/post_catalog.dart';
import '../posts/post_composer_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/post_repository.dart';
import '../posts/post_type_sheet.dart';
import 'home_feed_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.profile, super.key});

  final RegisteredProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final PostRepository _postsRepository;
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  PostCategory _category = PostCategory.help;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(PushNotificationService.instance.initializeForCurrentUser());
    _postsRepository = PostRepository(Supabase.instance.client);
    _loadPosts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotificationService.instance.refreshAfterResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _openDetail(String postId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );
    if (mounted) await _loadPosts();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: HomeBottomBar(onWallTap: _scrollToTop),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publish,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publicar'),
        backgroundColor: YuntaColors.action,
        foregroundColor: YuntaColors.inkStrong,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: () => _loadPosts(showLoader: true),
              color: YuntaColors.primary,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
                children: [
                  HomeFeedHeader(displayName: widget.profile.displayName),
                  const SizedBox(height: 24),
                  HomeCategorySelector(
                    selected: _category,
                    onSelected: (category) =>
                        setState(() => _category = category),
                  ),
                  if (emergencyCount > 0 && _category != PostCategory.emergency)
                    HomeEmergencyBanner(
                      count: emergencyCount,
                      onTap: () =>
                          setState(() => _category = PostCategory.emergency),
                    ),
                  const SizedBox(height: 22),
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
                    HomeLoadError(
                      message: _error!,
                      onRetry: () => _loadPosts(showLoader: true),
                    )
                  else if (visiblePosts.isEmpty)
                    HomeEmptyState(category: _category)
                  else
                    for (final post in visiblePosts) ...[
                      PostCard(
                        post: post,
                        onTap: () => _openDetail(post['id'] as String),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
