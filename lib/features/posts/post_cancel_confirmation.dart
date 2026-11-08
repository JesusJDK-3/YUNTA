import 'package:flutter/material.dart';

Future<bool?> confirmPostCancellation(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Retirar aviso'),
    content: const Text('Los vecinos ya no podrán unirse a este caso.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Volver'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Retirar'),
      ),
    ],
  ),
);
