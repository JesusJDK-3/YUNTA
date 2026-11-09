import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

const _postDetailTitles = {
  'emergency': 'Detalle de emergencia',
  'products_services': 'Detalle del anuncio',
};

String postDetailTitleFor(String? category) =>
    _postDetailTitles[category] ?? 'Detalle del favor';

class PostDetailMetricCard extends StatelessWidget {
  const PostDetailMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: YuntaColors.outlineSoft),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withValues(alpha: .2),
          child: Icon(icon, size: 18, color: YuntaColors.primary),
        ),
        const SizedBox(height: 9),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    ),
  );
}

class PostDetailPrivacyNote extends StatelessWidget {
  const PostDetailPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceBlue,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      children: [
        Icon(Icons.shield_outlined, color: YuntaColors.primary),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Tu teléfono y ubicación exacta se mantienen privados. '
            'Aquí solo ves una distancia aproximada.',
          ),
        ),
      ],
    ),
  );
}

class PostRatingPrompt extends StatelessWidget {
  const PostRatingPrompt({
    required this.provider,
    required this.onTap,
    super.key,
  });

  final String provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: YuntaColors.surfaceMint,
    child: ListTile(
      leading: const Icon(
        Icons.star_outline_rounded,
        color: YuntaColors.primary,
      ),
      title: const Text('Califica a quien te ayudó'),
      subtitle: Text('Cuéntanos cómo fue la ayuda de $provider.'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

String? postPublishedAgo(Object? value) {
  if (value is! String) return null;
  final created = DateTime.tryParse(value)?.toLocal();
  if (created == null) return null;
  final elapsed = DateTime.now().difference(created);
  if (elapsed.isNegative || elapsed.inMinutes < 1) {
    return 'Publicado hace un momento';
  }
  if (elapsed.inHours < 1) return 'Publicado hace ${elapsed.inMinutes} min';
  if (elapsed.inDays < 1) return 'Publicado hace ${elapsed.inHours} h';
  return 'Publicado hace ${elapsed.inDays} d';
}
