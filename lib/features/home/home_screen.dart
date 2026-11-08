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
import 'home_bottom_bar.dart';
import 'home_cases_screen.dart';
import 'home_feed_header.dart';
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
      unawaited(_loadPosts());
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
    final result = await Navigator.of(context).push<PostPublishResult>(
      MaterialPageRoute(
        builder: (_) => PostComposerScreen(
          type: type,
          initialLocation: widget.profile.location,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _category = type.category);
    await _loadPosts(showLoader: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == PostPublishResult.photoUploadFailed
              ? 'Aviso publicado. La foto no se pudo guardar.'
              : 'Aviso publicado en Yunta.',
        ),
      ),
    );
  }

  Future<void> _openDetail(String postId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );
    if (mounted) await _loadPosts();
  }

  Future<void> _openCases() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const HomeCasesScreen()));
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final category in PostCategory.values)
        category: _posts
            .where((post) => post['category'] == category.databaseValue)
            .length,
    };
    final emergency = _posts.cast<Map<String, dynamic>?>().firstWhere(
      (post) => post?['category'] == PostCategory.emergency.databaseValue,
      orElse: () => null,
    );
    final visiblePosts = _posts
        .where((post) {
          if (post['category'] != _category.databaseValue) return false;
          return _category != PostCategory.emergency ||
              post['id'] != emergency?['id'];
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: YuntaColors.homeCanvas,
      bottomNavigationBar: SafeArea(
        top: false,
        child: HomeBottomBar(onWallTap: _scrollToTop, onCasesTap: _openCases),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _publish,
        tooltip: 'Publicar aviso',
        child: const Icon(Icons.add_rounded, size: 31),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  HomeFeedHeader(
                    displayName: widget.profile.displayName,
                    locationSource: widget.profile.locationSource,
                  ),
                  const SizedBox(height: 16),
                  HomeCategorySelector(
                    selected: _category,
                    counts: counts,
                    onSelected: (category) =>
                        setState(() => _category = category),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 38),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    HomeLoadError(
                      message: _error!,
                      onRetry: () => _loadPosts(showLoader: true),
                    )
                  else ...[
                    if (emergency != null) ...[
                      const SizedBox(height: 4),
                      PostCard(
                        post: emergency,
                        featuredEmergency: true,
                        onTap: () => _openDetail(emergency['id'] as String),
                      ),
                    ],
                    if (visiblePosts.isEmpty &&
                        !(_category == PostCategory.emergency &&
                            emergency != null)) ...[
                      const SizedBox(height: 16),
                      HomeEmptyState(category: _category),
                    ] else
                      for (final post in visiblePosts) ...[
                        const SizedBox(height: 12),
                        PostCard(
                          post: post,
                          onTap: () => _openDetail(post['id'] as String),
                        ),
                      ],
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
