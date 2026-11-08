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
    final areaLabel = post['area_label'] as String?;
    final hasAreaLabel =
        areaLabel != null &&
        areaLabel.trim().isNotEmpty &&
        areaLabel.trim().toLowerCase() != 'zona aproximada';
    final locationLabel = [
      if (hasAreaLabel) areaLabel.trim(),
      if (distance != null) 'A $distance m',
    ].join(' · ');
    final mode = post['coordination_mode'] == 'group' ? 'Grupal' : 'Individual';
    final members = (post['member_count'] as num?)?.toInt() ?? 0;
    final recommendations =
        (post['recommendation_count'] as num?)?.toInt() ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      color: YuntaColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: emergency
              ? YuntaColors.danger.withValues(alpha: .5)
              : YuntaColors.outlineSoft,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emergency
                      ? YuntaColors.dangerSoft
                      : YuntaColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  type?.icon ?? Icons.campaign_outlined,
                  color: emergency ? YuntaColors.danger : YuntaColors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type?.publishLabel ??
                                type?.label ??
                                'Aviso vecinal',
                            style: TextStyle(
                              color: emergency
                                  ? YuntaColors.danger
                                  : YuntaColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          mode,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post['title'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post['description'] as String? ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _PostFact(
                          icon: Icons.location_on_outlined,
                          label: locationLabel.isEmpty
                              ? 'Cerca de ti'
                              : locationLabel,
                        ),
                        _PostFact(
                          icon: Icons.circle,
                          label: postStatusLabel(
                            post['status'] as String? ?? '',
                          ),
                          color: active
                              ? YuntaColors.success
                              : YuntaColors.muted,
                          iconSize: 9,
                        ),
                        if (members > 0)
                          _PostFact(
                            icon: Icons.people_outline,
                            label:
                                '$members ${members == 1 ? 'vecino' : 'vecinos'}',
                          ),
                        if (post['category'] == 'products_services')
                          _PostFact(
                            icon: Icons.thumb_up_alt_outlined,
                            label: '$recommendations recomendaciones',
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Publicado por ${post['author_name'] ?? 'Vecino'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostFact extends StatelessWidget {
  const _PostFact({
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
      Text(label, style: TextStyle(color: color)),
    ],
  );
}
