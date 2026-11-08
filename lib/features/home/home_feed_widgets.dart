import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/yunta_wordmark.dart';
import '../notifications/notification_bell.dart';
import '../posts/post_catalog.dart';

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({required this.displayName, super.key});

  final String displayName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const YuntaWordmark(compact: true),
          Semantics(
            label: 'Perfil de $displayName',
            child: CircleAvatar(
              radius: 23,
              backgroundColor: YuntaColors.surfaceMintStrong,
              child: Text(
                displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: YuntaColors.inkStrong,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Text('Cerca de ti', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 5),
      Text(
        'Hola, $displayName',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 14),
      const _RadiusPill(),
    ],
  );
}

class HomeCategorySelector extends StatelessWidget {
  const HomeCategorySelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final PostCategory selected;
  final ValueChanged<PostCategory> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final category in PostCategory.values) ...[
          ChoiceChip(
            selected: selected == category,
            selectedColor: category == PostCategory.emergency
                ? YuntaColors.dangerSoft
                : YuntaColors.primary,
            checkmarkColor: category == PostCategory.emergency
                ? YuntaColors.danger
                : Colors.white,
            labelStyle: TextStyle(
              color: selected == category
                  ? category == PostCategory.emergency
                        ? YuntaColors.danger
                        : Colors.white
                  : YuntaColors.ink,
              fontWeight: FontWeight.w600,
            ),
            avatar: Icon(
              category.icon,
              size: 19,
              color: category == PostCategory.emergency
                  ? YuntaColors.danger
                  : selected == category
                  ? Colors.white
                  : YuntaColors.primary,
            ),
            label: Text(category.label),
            onSelected: (_) => onSelected(category),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

class HomeEmergencyBanner extends StatelessWidget {
  const HomeEmergencyBanner({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: YuntaColors.dangerSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      onTap: onTap,
      leading: const Icon(
        Icons.warning_amber_rounded,
        color: YuntaColors.danger,
        size: 28,
      ),
      title: Text(
        '$count ${count == 1 ? 'aviso' : 'avisos'} de emergencia cerca',
        style: const TextStyle(
          color: YuntaColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward, color: YuntaColors.danger),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({required this.category, super.key});

  final PostCategory category;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceWhite,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: YuntaColors.outlineSoft.withValues(alpha: .6)),
    ),
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: YuntaColors.surfaceBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, size: 30, color: YuntaColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Aún no hay avisos de ${category.label.toLowerCase()} cerca.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Cuando un vecino publique, aparecerá aquí.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class HomeLoadError extends StatelessWidget {
  const HomeLoadError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 32),
      const Icon(Icons.cloud_off_outlined, size: 40, color: YuntaColors.muted),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
    ],
  );
}

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({required this.onWallTap, super.key});

  final VoidCallback onWallTap;

  @override
  Widget build(BuildContext context) => BottomAppBar(
    height: 68,
    color: YuntaColors.surfaceWhite,
    surfaceTintColor: Colors.transparent,
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    child: Row(
      children: [
        Expanded(
          child: _BottomItem(
            icon: Icons.home_rounded,
            label: 'Muro',
            selected: true,
            onTap: onWallTap,
          ),
        ),
        const Expanded(child: SizedBox()),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NotificationBell(),
              Text('Actividad', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: YuntaColors.primary),
          Text(label, style: const TextStyle(color: YuntaColors.primary)),
        ],
      ),
    ),
  );
}

class _RadiusPill extends StatelessWidget {
  const _RadiusPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceMint,
      border: Border.all(color: YuntaColors.outlineSoft),
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_outlined, color: YuntaColors.ink),
        SizedBox(width: 7),
        Text('Radio de 500 m', style: TextStyle(color: YuntaColors.ink)),
      ],
    ),
  );
}
