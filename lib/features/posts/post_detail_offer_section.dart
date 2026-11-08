import 'package:flutter/material.dart';

import 'post_detail_widgets.dart';

class PostDetailOfferSection extends StatelessWidget {
  const PostDetailOfferSection({
    required this.offers,
    required this.working,
    required this.onAccept,
    super.key,
  });

  final List<Map<String, dynamic>> offers;
  final bool working;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Vecinos que quieren ayudar',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        'Toca una tarjeta para aceptar el apoyo y abrir el chat.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      for (final offer in offers)
        PostOfferTile(
          offer: offer,
          onAccept: working ? null : () => onAccept(offer['user_id'] as String),
        ),
    ],
  );
}
