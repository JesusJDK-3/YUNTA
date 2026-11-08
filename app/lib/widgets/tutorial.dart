import 'package:flutter/material.dart';

const _steps = <(String, String)>[
  (
    'Publica en tres toques',
    'Abre Publicar, elige el favor y confirma. Escribir el título no es un toque más. El oficio, la emergencia y el recurso están en esa misma lista.',
  ),
  (
    'Coordina según el caso',
    'Entre dos, se acepta a una persona y el chat es de ustedes. En una cuadra, el grupo comparte el mismo chat.',
  ),
  (
    'La casa no sale en el muro',
    'Se ve la zona y una distancia redondeada. El celular y la dirección se escriben solo dentro del chat.',
  ),
];

/// Tutorial corto, se puede saltar, y no vuelve a salir en este celular.
class TutorialCard extends StatelessWidget {
  const TutorialCard({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _TutorialBody(onDone: onDone);
  }
}

class _TutorialBody extends StatefulWidget {
  const _TutorialBody({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_TutorialBody> createState() => _TutorialBodyState();
}

class _TutorialBodyState extends State<_TutorialBody> {
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final lesson = _steps[_step];
    return ColoredBox(
      color: const Color(0x73245062),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_step + 1} de ${_steps.length}'),
                const SizedBox(height: 8),
                Text(lesson.$1, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(lesson.$2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {
                        if (_step < _steps.length - 1) {
                          setState(() => _step += 1);
                        } else {
                          widget.onDone();
                        }
                      },
                      child: Text(_step < _steps.length - 1 ? 'Siguiente' : 'Ir al muro'),
                    ),
                    if (_step < _steps.length - 1) ...[
                      const SizedBox(width: 8),
                      TextButton(onPressed: widget.onDone, child: const Text('Saltar')),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
