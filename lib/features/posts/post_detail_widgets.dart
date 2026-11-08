import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class PostEmergencyNote extends StatelessWidget {
  const PostEmergencyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EE),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: YuntaColors.danger.withValues(alpha: .45)),
    ),
    child: const Text(
      'Coordina la ayuda dentro del grupo del aviso. Si hay peligro inmediato, '
      'contacta también a los servicios de emergencia de tu zona.',
    ),
  );
}

class PostOfferTile extends StatelessWidget {
  const PostOfferTile({required this.offer, required this.onAccept, super.key});

  final Map<String, dynamic> offer;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(offer['display_name'] as String? ?? 'Vecino'),
      subtitle: const Text('Quiere participar en este caso'),
      trailing: IconButton(
        tooltip: 'Aceptar y abrir chat',
        onPressed: onAccept,
        icon: const Icon(Icons.check_circle_outline),
      ),
    ),
  );
}

class PostDetailFact extends StatelessWidget {
  const PostDetailFact({
    required this.icon,
    required this.label,
    this.color = YuntaColors.ink,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}
