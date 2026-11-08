import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';
import '../../shared/widgets/yunta_wordmark.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.displayName, super.key});

  final String displayName;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const YuntaWordmark(compact: true),
            const SizedBox(height: 38),
            Text(
              'Cerca de ti',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: YuntaColors.outline, width: 1.4),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, color: YuntaColors.ink),
                  SizedBox(width: 7),
                  Text(
                    'Radio de 500 m',
                    style: TextStyle(color: YuntaColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Hola, $displayName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    size: 44,
                    color: YuntaColors.ink.withValues(alpha: .6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tu registro está listo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Aquí aparecerán avisos reales cuando estén disponibles cerca de ti.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}
