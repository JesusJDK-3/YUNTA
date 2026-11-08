import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import 'post_catalog.dart';

Future<PostTypeDefinition?> showPostTypeSheet(BuildContext context) =>
    showModalBottomSheet<PostTypeDefinition>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _PostTypeSheet(),
    );

class _PostTypeSheet extends StatelessWidget {
  const _PostTypeSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .78,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: YuntaColors.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '¿Qué quieres publicar?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          const Text('Elige el tipo de aviso para tus vecinos.'),
          const SizedBox(height: 18),
          for (final category in PostCategory.values) ...[
            _CategoryHeading(category: category),
            for (final type in postTypes.where(
              (item) => item.category == category,
            ))
              _TypeOption(type: type),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({required this.category});

  final PostCategory category;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(
          category.icon,
          size: 19,
          color: category == PostCategory.emergency
              ? YuntaColors.danger
              : YuntaColors.ink,
        ),
        const SizedBox(width: 8),
        Text(category.label, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({required this.type});

  final PostTypeDefinition type;

  @override
  Widget build(BuildContext context) {
    final emergency = type.category == PostCategory.emergency;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        type.icon,
        color: emergency ? YuntaColors.danger : YuntaColors.ink,
      ),
      title: Text(type.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(type),
    );
  }
}
