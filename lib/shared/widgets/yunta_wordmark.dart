import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class YuntaWordmark extends StatelessWidget {
  const YuntaWordmark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: Image.asset(
          'assets/yunta-192.png',
          width: compact ? 48 : 62,
          height: compact ? 48 : 62,
          fit: BoxFit.cover,
          semanticLabel: 'Logotipo Yunta, letra Y',
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'Yunta',
        style: TextStyle(
          color: YuntaColors.ink,
          fontSize: compact ? 27 : 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}
