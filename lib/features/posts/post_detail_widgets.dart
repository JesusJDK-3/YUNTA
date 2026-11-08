import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class PostDetailSummaryCard extends StatelessWidget {
  const PostDetailSummaryCard({
    required this.icon,
    required this.typeLabel,
    required this.mode,
    required this.title,
    required this.author,
    required this.locationLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.memberCount,
    required this.description,
    this.emergency = false,
    super.key,
  });

  final IconData icon;
  final String typeLabel;
  final String mode;
  final String title;
  final String author;
  final String locationLabel;
  final String statusLabel;
  final Color statusColor;
  final int memberCount;
  final String description;
  final bool emergency;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: emergency
                    ? YuntaColors.dangerSoft
                    : YuntaColors.surfaceBlue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: emergency ? YuntaColors.danger : YuntaColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                typeLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: emergency ? YuntaColors.danger : YuntaColors.primary,
                ),
              ),
            ),
            _ModePill(label: mode),
          ],
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(
          'Publicado por $author',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (locationLabel.isNotEmpty)
              PostDetailFact(
                icon: Icons.location_on_outlined,
                label: locationLabel,
              ),
            PostDetailFact(
              icon: Icons.circle,
              label: statusLabel,
              color: statusColor,
            ),
            PostDetailFact(
              icon: Icons.groups_outlined,
              label: '$memberCount participantes',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 7),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceMint,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

class PostEmergencyNote extends StatelessWidget {
  const PostEmergencyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EE),
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

class PostDetailFact extends StatelessWidget {
  const PostDetailFact({
    required this.icon,
    required this.label,
    this.color = YuntaColors.ink,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}
