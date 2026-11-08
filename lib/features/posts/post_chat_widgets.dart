import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class ChatParticipantHeader extends StatelessWidget {
  const ChatParticipantHeader({
    required this.name,
    required this.subtitle,
    required this.group,
    this.onOpenDetails,
    super.key,
  });

  final String name;
  final String subtitle;
  final bool group;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.characters.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 12),
      color: YuntaColors.surfaceBlue,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: YuntaColors.surfaceWhite,
            foregroundColor: YuntaColors.primary,
            child: Text(
              initial.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      group ? Icons.groups_outlined : Icons.near_me_outlined,
                      size: 16,
                      color: YuntaColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onOpenDetails != null) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onOpenDetails,
              icon: const Icon(Icons.info_outline_rounded, size: 17),
              label: const Text('Detalles'),
              style: OutlinedButton.styleFrom(
                foregroundColor: YuntaColors.primary,
                backgroundColor: YuntaColors.surfaceWhite,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatCoordinationBanner extends StatelessWidget {
  const ChatCoordinationBanner({
    required this.title,
    required this.status,
    required this.group,
    required this.canFinish,
    required this.resolving,
    required this.onFinish,
    super.key,
  });

  final String title;
  final String status;
  final bool group;
  final bool canFinish;
  final bool resolving;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'open' => 'Abierto · buscando apoyo',
      'coordinating' => group ? 'Grupo AYNI activo' : 'AYNI activo',
      'resolved' => 'Caso finalizado',
      _ => 'Coordinación vecinal',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 10, 13, 11),
      color: YuntaColors.primary,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: YuntaColors.accent),
                  const SizedBox(width: 7),
                  Text(
                    'Estado: ${_statusLabel(status)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: YuntaColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: YuntaColors.inkStrong,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: YuntaColors.accent,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (canFinish) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: resolving ? null : onFinish,
                  icon: resolving
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 17,
                        ),
                  label: Text(resolving ? 'Guardando' : 'Finalizar caso'),
                  style: FilledButton.styleFrom(
                    backgroundColor: YuntaColors.mint,
                    foregroundColor: YuntaColors.inkStrong,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String value) => switch (value) {
    'open' => 'Abierto',
    'coordinating' => 'En curso',
    'resolved' => 'Resuelto',
    'cancelled' => 'Cancelado',
    _ => 'Coordinación',
  };
}

class ChatPrivacyNote extends StatelessWidget {
  const ChatPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: YuntaColors.primary,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Chat privado para participantes de este caso en Yunta',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}
