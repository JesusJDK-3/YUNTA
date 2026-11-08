import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class RegistrationPrivacyBanner extends StatelessWidget {
  const RegistrationPrivacyBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: YuntaColors.registrationSky,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: YuntaColors.surfaceWhite,
          child: Icon(Icons.shield_outlined, color: YuntaColors.primary),
        ),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Solo compartimos tu distancia aproximada; nunca tu dirección '
            'exacta ni tu número de teléfono.',
          ),
        ),
      ],
    ),
  );
}

class RegistrationCountryCode extends StatelessWidget {
  const RegistrationCountryCode({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    decoration: BoxDecoration(
      color: YuntaColors.surfaceMint,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 15,
          child: CustomPaint(painter: _PeruFlagPainter()),
        ),
        SizedBox(width: 7),
        Text('+51', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _PeruFlagPainter extends CustomPainter {
  const _PeruFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFD91023);
    final white = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 3, size.height), red);
    canvas.drawRect(
      Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height),
      white,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height),
      red,
    );
  }

  @override
  bool shouldRepaint(covariant _PeruFlagPainter oldDelegate) => false;
}

class RegistrationFooter extends StatelessWidget {
  const RegistrationFooter({
    required this.busy,
    required this.onSubmit,
    required this.onTutorial,
    super.key,
  });

  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onTutorial;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      color: YuntaColors.registrationCanvas,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(busy ? 'Guardando…' : 'Entrar a AYNI'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: YuntaColors.action,
              foregroundColor: YuntaColors.inkStrong,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onTutorial,
            icon: const Icon(Icons.play_circle_outline_rounded, size: 19),
            label: const Text('Ver breve tutorial · 1 min'),
            style: TextButton.styleFrom(
              backgroundColor: YuntaColors.surfaceMint,
              foregroundColor: YuntaColors.inkStrong,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    ),
  );
}
