import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

Future<void> showAyniProfileSheet(
  BuildContext context, {
  required String displayName,
  required double ratingAverage,
  required int ratingCount,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => AyniProfileSheet(
      displayName: displayName,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
    ),
  );
}

class AyniProfileSheet extends StatelessWidget {
  const AyniProfileSheet({
    required this.displayName,
    required this.ratingAverage,
    required this.ratingCount,
    super.key,
  });

  final String displayName;
  final double ratingAverage;
  final int ratingCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Perfil vecinal', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 22),
        CircleAvatar(
          radius: 34,
          backgroundColor: YuntaColors.surfaceMint,
          child: Text(
            displayName.trim().isEmpty
                ? '?'
                : displayName.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: YuntaColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ProfileRatingSummary(average: ratingAverage, count: ratingCount),
        const SizedBox(height: 14),
        Text(
          'Valoraciones recibidas después de casos finalizados.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class ProfileRatingSummary extends StatelessWidget {
  const ProfileRatingSummary({
    required this.average,
    required this.count,
    super.key,
  });

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final filled = count == 0 ? 0 : average.round().clamp(0, 5);
    return Semantics(
      label: count == 0
          ? 'Aún sin valoraciones'
          : 'Calificación de ${average.toStringAsFixed(1)} de 5, $count valoraciones',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var star = 1; star <= 5; star++)
                Icon(
                  star <= filled
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 21,
                  color: count == 0
                      ? YuntaColors.outline
                      : const Color(0xFFE3A92F),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            count == 0
                ? 'Aún sin valoraciones'
                : '${average.toStringAsFixed(1)} · $count valoraciones',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: YuntaColors.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
