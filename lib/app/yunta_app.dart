import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/yunta_theme.dart';
import '../features/auth/registration_screen.dart';
import '../features/auth/profile_repository.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notification_inbox_screen.dart';
import '../shared/widgets/ayni_wordmark.dart';
import 'yunta_navigation.dart';

class YuntaApp extends StatelessWidget {
  const YuntaApp({required this.supabaseConfigured, super.key});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: yuntaNavigatorKey,
    scaffoldMessengerKey: yuntaMessengerKey,
    title: 'AYNI',
    debugShowCheckedModeBanner: false,
    theme: YuntaTheme.light,
    routes: {'/notifications': (_) => const NotificationInboxScreen()},
    home: SessionGate(supabaseConfigured: supabaseConfigured),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({required this.supabaseConfigured, super.key});

  final bool supabaseConfigured;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<_StartupResult> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _resolveStartup();
  }

  Future<_StartupResult> _resolveStartup() async {
    final minimumSplash = Future<void>.delayed(const Duration(seconds: 3));
    try {
      final profile = widget.supabaseConfigured ? await _loadProfile() : null;
      await minimumSplash;
      return _StartupResult(
        configured: widget.supabaseConfigured,
        profile: profile,
      );
    } catch (_) {
      await minimumSplash;
      rethrow;
    }
  }

  Future<RegisteredProfile?> _loadProfile() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return null;
    return ProfileRepository(client).getMyProfile();
  }

  void _registered(RegisteredProfile profile) => setState(() {
    _startup = Future.value(_StartupResult(configured: true, profile: profile));
  });

  void _retry() => setState(() {
    _startup = _resolveStartup();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<_StartupResult>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.hasError) return ProfileLoadError(onRetry: _retry);
      if (snapshot.connectionState != ConnectionState.done) {
        return const AyniSplashScreen();
      }
      final result = snapshot.data!;
      if (!result.configured) return const ConfigurationScreen();
      final profile = result.profile;
      if (profile == null) {
        return RegistrationScreen(onRegistered: _registered);
      }
      return HomeScreen(profile: profile);
    },
  );
}

class _StartupResult {
  const _StartupResult({required this.configured, required this.profile});

  final bool configured;
  final RegisteredProfile? profile;
}

class AyniSplashScreen extends StatelessWidget {
  const AyniSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AyniWordmark(),
              const SizedBox(height: 28),
              SizedBox.square(
                dimension: 42,
                child: reduceMotion
                    ? const CircularProgressIndicator(value: .7)
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(seconds: 3),
                        curve: Curves.easeInOutCubic,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(value: value),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                'Preparando AYNI…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AyniWordmark(),
              const SizedBox(height: 28),
              Text(
                'Falta conectar AYNI',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Configura la URL y la publishable key de Supabase para iniciar.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProfileLoadError extends StatelessWidget {
  const ProfileLoadError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AyniWordmark(),
              const SizedBox(height: 24),
              const Text('No pudimos cargar tu perfil. Revisa tu conexión.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    ),
  );
}
