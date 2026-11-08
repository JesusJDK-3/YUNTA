import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class AmbientBubbles extends StatefulWidget {
  const AmbientBubbles({super.key});

  @override
  State<AmbientBubbles> createState() => _AmbientBubblesState();
}

class _AmbientBubblesState extends State<AmbientBubbles>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _appResumed = true;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      _syncMotion();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (_appResumed && _reduceMotion != true) {
      if (!_motion.isAnimating) _motion.repeat(reverse: true);
    } else {
      _motion.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        _reduceMotion ?? MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 116,
      width: 144,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) => CustomPaint(
          painter: _BubblePainter(reduceMotion ? 0.5 : _motion.value),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <(double, double, double, double)>[
      (0.27, 0.58, 22, 0.0),
      (0.54, 0.39, 31, 0.36),
      (0.79, 0.62, 16, 0.68),
    ];
    for (final (x, y, radius, phase) in points) {
      final drift = math.sin((progress + phase) * math.pi) * 5;
      final center = Offset(size.width * x + drift, size.height * y - drift);
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = YuntaColors.yellowPale.withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        center.translate(-radius * 0.28, -radius * 0.34),
        radius * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.78),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
