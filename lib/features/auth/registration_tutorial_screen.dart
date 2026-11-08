import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class RegistrationTutorialScreen extends StatelessWidget {
  const RegistrationTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Así funciona Yunta')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                'Ayudarse cerca es más fácil.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Tres pasos para conectar con tus vecinos.'),
              const SizedBox(height: 22),
              const _TutorialStep(
                number: '1',
                icon: Icons.edit_note_rounded,
                title: 'Publica un aviso',
                description:
                    'Cuenta qué necesitas o comparte un producto o servicio.',
              ),
              const Divider(height: 24),
              const _TutorialStep(
                number: '2',
                icon: Icons.near_me_outlined,
                title: 'Encuentra ayuda cerca',
                description:
                    'Explora avisos dentro de un radio aproximado de 500 m.',
              ),
              const Divider(height: 24),
              const _TutorialStep(
                number: '3',
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Coordina en el chat',
                description:
                    'Al participar, puedes hablar con los vecinos del aviso.',
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 23,
        backgroundColor: YuntaColors.surfaceMint,
        child: Icon(icon, color: YuntaColors.primary),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. $title',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(description),
          ],
        ),
      ),
    ],
  );
}
