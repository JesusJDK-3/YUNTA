import 'package:flutter/material.dart';

/// La Y del equipo se conserva. No se reemplaza por otro símbolo.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 52.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Logotipo Yunta, letra Y',
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF3D76F), shape: BoxShape.circle),
            child: Text('Y', style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w800, color: Color(0xFF193D4B))),
          ),
        ),
        const SizedBox(width: 8),
        Text('Yunta', style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class NoticeBanner extends StatelessWidget {
  const NoticeBanner(this.text, {super.key, this.alert = false});
  final String text;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert ? const Color(0xFFF6D7D4) : const Color(0xFFF3E2C4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}
