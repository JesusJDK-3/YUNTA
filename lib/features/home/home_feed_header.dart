import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/yunta_wordmark.dart';
import '../notifications/notification_bell.dart';

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({
    required this.displayName,
    required this.locationSource,
    super.key,
  });

  final String displayName;
  final String locationSource;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.characters.first.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: YuntaWordmark(compact: true)),
            _smallRadiusPill(),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: YuntaColors.surfaceMint,
              child: Text(initial, style: _avatarText),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: YuntaColors.inkStrong),
                  ),
                  Text(
                    'Comunidad vecinal cercana',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(child: NotificationBell()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _zoneCard(context),
      ],
    );
  }

  Widget _smallRadiusPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: YuntaColors.surfaceMintStrong),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: YuntaColors.action),
        SizedBox(width: 6),
        Text('500 m de ti', style: TextStyle(color: YuntaColors.ink)),
      ],
    ),
  );

  Widget _zoneCard(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.near_me_outlined, color: YuntaColors.actionPressed),
        const SizedBox(width: 10),
        Text('En tu zona', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 10),
        _zonePill(context, '500 m'),
        const Spacer(),
        Icon(
          Icons.circle,
          size: 8,
          color: locationSource == 'gps'
              ? YuntaColors.success
              : YuntaColors.muted,
        ),
        const SizedBox(width: 5),
        Text(
          locationSource == 'gps' ? 'GPS' : 'Mapa',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    ),
  );

  Widget _zonePill(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceMint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );

  static const _avatarText = TextStyle(
    color: YuntaColors.ink,
    fontWeight: FontWeight.w800,
  );
}
