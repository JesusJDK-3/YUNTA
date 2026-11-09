import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/ayni_wordmark.dart';
import '../notifications/notification_bell.dart';

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({
    required this.displayName,
    required this.locationSource,
    required this.onProfileTap,
    required this.onLocationTap,
    this.locationWorking = false,
    super.key,
  });

  final String displayName;
  final String locationSource;
  final VoidCallback onProfileTap;
  final VoidCallback onLocationTap;
  final bool locationWorking;

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
            const Expanded(child: _AyniHomeBrand()),
            _smallRadiusPill(),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Abrir mi perfil',
              child: InkWell(
                onTap: onProfileTap,
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: YuntaColors.surfaceMint,
                  child: Text(initial, style: _avatarText),
                ),
              ),
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

  Widget _zoneCard(BuildContext context) => Semantics(
    button: true,
    label:
        'Actualizar ubicación. Radio de 500 metros. '
        '${locationSource == 'gps' ? 'Ubicación por GPS' : 'Punto elegido en el mapa'}',
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: locationWorking ? null : onLocationTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.near_me_outlined,
                color: YuntaColors.actionPressed,
              ),
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
              const SizedBox(width: 4),
              locationWorking
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: YuntaColors.ink,
                    ),
            ],
          ),
        ),
      ),
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

class _AyniHomeBrand extends StatelessWidget {
  const _AyniHomeBrand();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/ayni-neighbors.png',
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        semanticLabel: 'Vecinos brindando apoyo mutuo',
      ),
      const SizedBox(width: 6),
      const Flexible(child: AyniWordmark(compact: true)),
    ],
  );
}
