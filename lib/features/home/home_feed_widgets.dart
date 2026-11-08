import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import '../posts/post_catalog.dart';

class HomeCategorySelector extends StatelessWidget {
  const HomeCategorySelector({
    required this.selected,
    required this.counts,
    required this.onSelected,
    super.key,
  });

  final PostCategory selected;
  final Map<PostCategory, int> counts;
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
                ? YuntaColors.danger
                : YuntaColors.action,
            checkmarkColor: category == PostCategory.emergency
                ? Colors.white
                : YuntaColors.inkStrong,
            label: Text('${_shortLabel(category)} (${counts[category] ?? 0})'),
            labelStyle: TextStyle(
              color: selected == category
                  ? category == PostCategory.emergency
                        ? Colors.white
                        : YuntaColors.inkStrong
                  : YuntaColors.ink,
              fontWeight: FontWeight.w700,
            ),
            avatar: Icon(
              category.icon,
              size: 18,
              color: selected == category
                  ? category == PostCategory.emergency
                        ? Colors.white
                        : YuntaColors.inkStrong
                  : YuntaColors.primary,
            ),
            onSelected: (_) => onSelected(category),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );

  String _shortLabel(PostCategory category) => switch (category) {
    PostCategory.help => 'Ayuda',
    PostCategory.productsServices => 'Productos y servicios',
    PostCategory.emergency => 'Emergencias',
  };
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({required this.category, super.key});

  final PostCategory category;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        Icon(category.icon, size: 35, color: YuntaColors.primary),
        const SizedBox(height: 13),
        Text(
          'Aún no hay avisos de ${category.label.toLowerCase()} cerca.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(
          'Cuando un vecino publique, aparecerá aquí.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
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
      const SizedBox(height: 28),
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
