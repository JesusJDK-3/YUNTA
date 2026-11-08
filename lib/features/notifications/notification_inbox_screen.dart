import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/yunta_theme.dart';
import '../posts/post_detail_screen.dart';
import 'notification_repository.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  late final NotificationRepository _repository;
  late final Stream<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    _repository = NotificationRepository(Supabase.instance.client);
    _notifications = _repository.watchMine();
  }

  Future<void> _open(Map<String, dynamic> notification) async {
    try {
      if (notification['read_at'] == null) {
        await _repository.markRead(notification['id'] as String);
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              PostDetailScreen(postId: notification['post_id'] as String),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir esta notificación.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notificaciones')),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notifications,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudieron cargar las notificaciones.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!;
        if (notifications.isEmpty) {
          return const Center(child: Text('Aún no tienes notificaciones.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final unread = notification['read_at'] == null;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: unread
                    ? YuntaColors.yellowPale
                    : const Color(0xFFF1F5F6),
                child: Icon(_iconFor(notification['kind'] as String? ?? '')),
              ),
              title: Text(
                _title(notification),
                style: TextStyle(fontWeight: unread ? FontWeight.w700 : null),
              ),
              subtitle: Text('En «${notification['post_title'] ?? 'Aviso'}»'),
              trailing: unread
                  ? const Icon(Icons.circle, size: 10, color: YuntaColors.ink)
                  : null,
              onTap: () => _open(notification),
            );
          },
        );
      },
    ),
  );

  String _title(Map<String, dynamic> notification) {
    final actor = notification['actor_name'] as String? ?? 'Un vecino';
    return switch (notification['kind']) {
      'offer_received' => '$actor quiere ayudarte',
      'group_joined' => '$actor se unió a la coordinación',
      'offer_accepted' => '$actor aceptó tu ofrecimiento',
      _ => 'Hay actividad en tu aviso',
    };
  }

  IconData _iconFor(String kind) => switch (kind) {
    'offer_received' => Icons.volunteer_activism_outlined,
    'group_joined' => Icons.groups_outlined,
    'offer_accepted' => Icons.check_circle_outline,
    _ => Icons.notifications_none,
  };
}
