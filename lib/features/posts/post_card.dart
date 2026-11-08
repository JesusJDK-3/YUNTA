import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_catalog.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, required this.onTap, super.key});

  final Map<String, dynamic> post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = postTypeFor(post['type'] as String? ?? '');
    final emergency = post['category'] == 'emergency';
    final active = post['status'] == 'open' || post['status'] == 'coordinating';
    final distance = (post['distance_m'] as num?)?.round();
    final mode = post['coordination_mode'] == 'group' ? 'Grupal' : 'Individual';
    final members = (post['member_count'] as num?)?.toInt() ?? 0;
    final recommendations =
        (post['recommendation_count'] as num?)?.toInt() ?? 0;
    final author = post['author_name'] as String? ?? 'Vecino';
    final accent = emergency ? YuntaColors.danger : YuntaColors.primary;

    return Material(
      color: YuntaColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: emergency
              ? YuntaColors.danger.withValues(alpha: .5)
              : YuntaColors.outlineSoft,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: emergency
                          ? YuntaColors.dangerSoft
                          : YuntaColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      type?.icon ?? Icons.campaign_outlined,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type?.publishLabel ?? type?.label ?? 'Aviso vecinal',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: accent),
                    ),
                  ),
                  _ModePill(label: mode),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                post['title'] as String? ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                post['description'] as String? ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (distance != null)
                    _Fact(
                      icon: Icons.location_on_outlined,
                      label: 'A $distance m',
                    ),
                  _Fact(
                    icon: Icons.circle,
                    iconSize: 9,
                    label: postStatusLabel(post['status'] as String? ?? ''),
                    color: active ? YuntaColors.success : YuntaColors.muted,
                  ),
                  if (members > 0)
                    _Fact(
                      icon: Icons.people_outline,
                      label: '$members ${members == 1 ? 'vecino' : 'vecinos'}',
                    ),
                  if (post['category'] == 'products_services')
                    _Fact(
                      icon: Icons.thumb_up_alt_outlined,
                      label: '$recommendations recomendaciones',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 11),
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: YuntaColors.surfaceMint,
                    child: Text(
                      author.isEmpty
                          ? '?'
                          : author.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: YuntaColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Publicado por $author',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceBlue,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    this.color = YuntaColors.ink,
    this.iconSize = 16,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: iconSize, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 13)),
    ],
  );
}
