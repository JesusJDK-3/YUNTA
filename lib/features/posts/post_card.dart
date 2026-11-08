import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_catalog.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.onTap,
    this.featuredEmergency = false,
    super.key,
  });

  final Map<String, dynamic> post;
  final VoidCallback onTap;
  final bool featuredEmergency;

  @override
  Widget build(BuildContext context) {
    final type = postTypeFor(post['type'] as String? ?? '');
    final emergency = post['category'] == 'emergency';
    final active = post['status'] == 'open' || post['status'] == 'coordinating';
    final distance = (post['distance_m'] as num?)?.round();
    final members = (post['member_count'] as num?)?.toInt() ?? 0;
    final recommendations =
        (post['recommendation_count'] as num?)?.toInt() ?? 0;
    final author = post['author_name'] as String? ?? 'Vecino';
    final imageUrl = post['image_url'] as String?;
    final localImage = post['local_image_path'] as String?;
    final elapsed = emergency ? _elapsed(post['created_at']) : null;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(featuredEmergency ? 22 : 20),
        side: const BorderSide(color: YuntaColors.outlineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
              child: Row(
                children: [
                  if (emergency)
                    _Tag(
                      icon: Icons.warning_amber_rounded,
                      label: 'Alerta vecinal',
                      foreground: YuntaColors.danger,
                      background: YuntaColors.dangerSoft,
                    )
                  else
                    _Tag(
                      icon: type?.icon ?? Icons.campaign_outlined,
                      label: type?.label ?? 'Aviso vecinal',
                      foreground: YuntaColors.primary,
                      background: YuntaColors.surfaceMint,
                    ),
                  const SizedBox(width: 8),
                  if (distance != null)
                    Flexible(
                      child: _CompactFact(label: _distanceLabel(distance)),
                    ),
                  if (elapsed != null) ...[
                    const SizedBox(width: 6),
                    Flexible(child: _CompactFact(label: elapsed)),
                  ],
                  const Spacer(),
                  _Tag(
                    label: post['coordination_mode'] == 'group'
                        ? 'Grupal'
                        : 'Individual',
                    foreground: YuntaColors.primary,
                    background: YuntaColors.surfaceMint,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
              child: Text(
                post['title'] as String? ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: YuntaColors.ink,
                  fontSize: featuredEmergency ? 19 : 18,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
              child: Text(
                post['description'] as String? ?? '',
                maxLines: featuredEmergency ? 3 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (localImage != null && localImage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(localImage),
                    width: double.infinity,
                    height: featuredEmergency ? 154 : 138,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ] else if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: featuredEmergency ? 154 : 138,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: active ? YuntaColors.success : YuntaColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      postStatusLabel(post['status'] as String? ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? YuntaColors.success : YuntaColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (members > 0) ...[
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 17,
                      color: YuntaColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text('$members ${members == 1 ? 'vecino' : 'vecinos'}'),
                  ],
                  if (recommendations > 0 &&
                      post['category'] == 'products_services') ...[
                    const Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 17,
                      color: YuntaColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text('$recommendations'),
                  ],
                  const SizedBox(width: 9),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: YuntaColors.surfaceMint,
                    child: Text(
                      author.trim().isEmpty
                          ? '?'
                          : author.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: YuntaColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: YuntaColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _distanceLabel(int meters) =>
      meters == 0 ? 'A menos de 10 m' : 'A $meters m';

  String? _elapsed(Object? value) {
    if (value is! String) return null;
    final created = DateTime.tryParse(value)?.toLocal();
    if (created == null) return null;
    final difference = DateTime.now().difference(created);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours} h';
    return 'Hace ${difference.inDays} d';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CompactFact extends StatelessWidget {
  const _CompactFact({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodySmall,
  );
}
