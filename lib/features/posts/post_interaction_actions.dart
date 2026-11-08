import 'package:flutter/material.dart';

class PostInteractionActions extends StatelessWidget {
  const PostInteractionActions({
    required this.isAuthor,
    required this.canChat,
    required this.group,
    required this.status,
    required this.membership,
    required this.type,
    required this.localAd,
    required this.working,
    required this.onOpenChat,
    required this.onJoin,
    required this.onResolve,
    required this.onCancel,
    required this.onReopen,
    required this.onEdit,
    super.key,
  });

  final bool isAuthor;
  final bool canChat;
  final bool group;
  final String status;
  final String membership;
  final String type;
  final bool localAd;
  final bool working;
  final VoidCallback onOpenChat;
  final VoidCallback onJoin;
  final VoidCallback onResolve;
  final VoidCallback onCancel;
  final VoidCallback onReopen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final active = status == 'open' || status == 'coordinating';
    final children = <Widget>[];
    if (isAuthor) {
      if (canChat) children.add(_chatButton(onOpenChat));
      if (active) {
        if (localAd) children.add(_editButton());
        children.add(_resolveButton());
        children.add(_cancelButton());
      }
      if (!group && (status == 'coordinating' || status == 'resolved')) {
        children.add(_reopenButton(onReopen, status == 'coordinating'));
      }
    } else if (canChat) {
      children.add(_chatButton(onOpenChat));
    } else if (membership == 'pending') {
      children.add(const Text('Tu ofrecimiento está pendiente de respuesta.'));
    } else if (active) {
      children.add(_joinButton());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in children) ...[child, const SizedBox(height: 8)],
      ],
    );
  }

  Widget _chatButton(VoidCallback onTap) => FilledButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.chat_bubble_outline),
    label: const Text('Abrir chat de coordinación'),
  );

  Widget _editButton() => OutlinedButton.icon(
    onPressed: working ? null : onEdit,
    icon: const Icon(Icons.edit_outlined),
    label: const Text('Editar anuncio'),
  );

  Widget _resolveButton() => FilledButton.tonalIcon(
    onPressed: working ? null : onResolve,
    icon: const Icon(Icons.check_circle_outline),
    label: const Text('Marcar como resuelto'),
  );

  Widget _cancelButton() => TextButton.icon(
    onPressed: working ? null : onCancel,
    icon: const Icon(Icons.delete_outline),
    label: const Text('Retirar aviso'),
  );

  Widget _reopenButton(VoidCallback onTap, bool replacing) =>
      OutlinedButton.icon(
        onPressed: working ? null : onTap,
        icon: const Icon(Icons.refresh),
        label: Text(replacing ? 'Buscar otro vecino' : 'Reabrir caso'),
      );

  Widget _joinButton() {
    final label = group
        ? 'Unirme a la coordinación'
        : switch (type) {
            'help_request' => 'AYNI · Brindar apoyo',
            'urgent_request' => 'Brindar apoyo urgente',
            'service' => 'Solicitar este servicio',
            _ => 'Me interesa',
          };
    return FilledButton.icon(
      onPressed: working ? null : onJoin,
      icon: working
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(group ? Icons.groups_outlined : Icons.volunteer_activism),
      label: Text(label),
    );
  }
}
