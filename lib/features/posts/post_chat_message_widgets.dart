import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class ChatTimelineList extends StatelessWidget {
  const ChatTimelineList({
    required this.messages,
    required this.userId,
    required this.participantNames,
    required this.controller,
    super.key,
  });

  final List<Map<String, dynamic>> messages;
  final String userId;
  final Map<String, String> participantNames;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const ChatEmptyState();
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final senderId = message['sender_id'] as String? ?? '';
        final mine = senderId == userId;
        final previous = index == 0
            ? null
            : DateTime.tryParse(
                messages[index - 1]['created_at'] as String? ?? '',
              )?.toLocal();
        final sentAt = DateTime.tryParse(message['created_at'] as String? ?? '')
            ?.toLocal();
        final showDate =
            sentAt != null && (previous == null || !_sameDay(previous, sentAt));
        return Column(
          children: [
            if (showDate) _ChatDateDivider(date: sentAt),
            _ChatMessageBubble(
              body: message['body'] as String? ?? '',
              senderName: participantNames[senderId] ?? 'Participante',
              mine: mine,
              sentAt: sentAt,
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _ChatDateDivider extends StatelessWidget {
  const _ChatDateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(date.year, date.month, date.day)).inDays ==
        1;
    final label = today
        ? 'Hoy'
        : yesterday
        ? 'Ayer'
        : '${date.day}/${date.month}/${date.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: YuntaColors.surfaceBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.body,
    required this.senderName,
    required this.mine,
    required this.sentAt,
  });

  final String body;
  final String senderName;
  final bool mine;
  final DateTime? sentAt;

  @override
  Widget build(BuildContext context) {
    final initial = senderName.trim().isEmpty
        ? '?'
        : senderName.characters.first.toUpperCase();
    final time = sentAt == null
        ? null
        : MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(sentAt!));
    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          CircleAvatar(
            radius: 15,
            backgroundColor: YuntaColors.surfaceMint,
            foregroundColor: YuntaColors.primary,
            child: Text(initial, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .82,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
            decoration: BoxDecoration(
              color: mine ? YuntaColors.action : YuntaColors.surfaceWhite,
              border: mine
                  ? null
                  : Border.all(
                      color: YuntaColors.outlineSoft.withValues(alpha: .6),
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 5),
                bottomRight: Radius.circular(mine ? 5 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!mine) ...[
                  Text(
                    senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  body,
                  style: const TextStyle(
                    color: YuntaColors.inkStrong,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      time,
                      style: TextStyle(
                        color: mine ? YuntaColors.ink : YuntaColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 34, color: YuntaColors.primary),
          const SizedBox(height: 12),
          Text(
            'Empieza la conversación',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Coordinen aquí los detalles de este caso.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class ChatReadOnlyNote extends StatelessWidget {
  const ChatReadOnlyNote({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: YuntaColors.surfaceWhite,
        border: Border(top: BorderSide(color: YuntaColors.outlineSoft)),
      ),
      child: Text(
        'Caso finalizado · chat disponible para consulta',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

class ChatLoadState extends StatelessWidget {
  const ChatLoadState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
