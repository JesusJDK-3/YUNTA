import 'package:flutter/material.dart';

enum HomeLocationUpdateMode { gps, map }

Future<HomeLocationUpdateMode?> showHomeLocationUpdateSheet(
  BuildContext context,
) => showModalBottomSheet<HomeLocationUpdateMode>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (_) => const _HomeLocationUpdateSheet(),
);

class _HomeLocationUpdateSheet extends StatelessWidget {
  const _HomeLocationUpdateSheet();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actualizar tu zona',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'El muro buscará avisos dentro de un radio de 500 m.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.my_location_rounded),
          title: const Text('Usar ubicación actual'),
          subtitle: const Text('Actualizar el punto con el GPS del teléfono.'),
          onTap: () => Navigator.pop(context, HomeLocationUpdateMode.gps),
        ),
        ListTile(
          leading: const Icon(Icons.map_outlined),
          title: const Text('Elegir punto en el mapa'),
          subtitle: const Text('Mover el mapa y marcar un nuevo punto.'),
          onTap: () => Navigator.pop(context, HomeLocationUpdateMode.map),
        ),
      ],
    ),
  );
}
