import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class PostDetailStickyBar extends StatelessWidget {
  const PostDetailStickyBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: YuntaColors.surfaceWhite,
        border: Border(top: BorderSide(color: YuntaColors.outlineSoft)),
      ),
      child: child,
    ),
  );
}

class PostDetailErrorView extends StatelessWidget {
  const PostDetailErrorView({
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
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class PostDetailStatusRow extends StatelessWidget {
  const PostDetailStatusRow({
    required this.distanceLabel,
    required this.statusLabel,
    required this.statusColor,
    super.key,
  });

  final String? distanceLabel;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (distanceLabel != null) ...[
        const Icon(
          Icons.near_me_outlined,
          size: 16,
          color: YuntaColors.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            distanceLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ] else
        const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: statusColor),
            const SizedBox(width: 6),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class PostDetailSummaryCard extends StatelessWidget {
  const PostDetailSummaryCard({
    required this.icon,
    required this.typeLabel,
    required this.title,
    required this.author,
    required this.description,
    required this.publishedLabel,
    this.emergency = false,
    super.key,
  });

  final IconData icon;
  final String typeLabel;
  final String title;
  final String author;
  final String description;
  final String? publishedLabel;
  final bool emergency;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: YuntaColors.outlineSoft),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TypePill(
                icon: icon,
                label: typeLabel,
                emergency: emergency,
              ),
            ),
            if (publishedLabel != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  publishedLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: YuntaColors.surfaceBlue.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descripción',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(description, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: YuntaColors.surfaceMint,
              child: Text(
                author.trim().isEmpty
                    ? '?'
                    : author.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: YuntaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Publicado por $author',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.icon,
    required this.label,
    required this.emergency,
  });

  final IconData icon;
  final String label;
  final bool emergency;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: emergency ? YuntaColors.dangerSoft : YuntaColors.surfaceBlue,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: emergency ? YuntaColors.danger : YuntaColors.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emergency ? YuntaColors.danger : YuntaColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class PostEmergencyNote extends StatelessWidget {
  const PostEmergencyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: YuntaColors.dangerSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: YuntaColors.danger.withValues(alpha: .45)),
    ),
    child: const Text(
      'Coordina la ayuda dentro del grupo del aviso. Si hay peligro inmediato, '
      'contacta también a los servicios de emergencia de tu zona.',
    ),
  );
}

class PostOfferTile extends StatelessWidget {
  const PostOfferTile({required this.offer, required this.onAccept, super.key});

  final Map<String, dynamic> offer;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(offer['display_name'] as String? ?? 'Vecino'),
      subtitle: const Text('Quiere participar en este caso'),
      trailing: IconButton(
        tooltip: 'Aceptar y abrir chat',
        onPressed: onAccept,
        icon: const Icon(Icons.check_circle_outline),
      ),
    ),
  );
}
