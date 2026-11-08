import 'package:flutter/material.dart';

class YuntaSplash extends StatefulWidget {
  const YuntaSplash({required this.child, super.key});

  final Widget child;

  @override
  State<YuntaSplash> createState() => _YuntaSplashState();
}

class _YuntaSplashState extends State<YuntaSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _showLogo = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.duration = const Duration(milliseconds: 360);
      }
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _showLogo = false);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_showLogo)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;
              final fadeIn = (progress / 0.22).clamp(0.0, 1.0);
              final fadeOut = progress < 0.62
                  ? 1.0
                  : (1 - (progress - 0.62) / 0.38).clamp(0.0, 1.0);
              return Opacity(
                opacity: fadeIn * fadeOut,
                child: Transform.scale(
                  scale: 0.94 + (0.06 * fadeIn),
                  child: child,
                ),
              );
            },
            child: const ColoredBox(
              color: Colors.white,
              child: Center(
                child: Image(
                  image: AssetImage('assets/ayni-logo.jpg'),
                  width: 280,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ayni, logotipo de Yunta',
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
