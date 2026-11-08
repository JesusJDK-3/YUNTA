import 'package:flutter/material.dart';

class AyniWordmark extends StatelessWidget {
  const AyniWordmark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Logotipo AYNI',
    child: Image.asset(
      'assets/ayni-wordmark.png',
      width: compact ? 104 : 184,
      height: compact ? 52 : 92,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}
