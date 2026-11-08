import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/yunta_theme.dart';
import '../features/auth/registration_screen.dart';
import '../features/auth/profile_repository.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notification_inbox_screen.dart';
import '../shared/widgets/yunta_wordmark.dart';
import 'yunta_navigation.dart';

class YuntaApp extends StatelessWidget {
  const YuntaApp({required this.supabaseConfigured, super.key});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: yuntaNavigatorKey,
    scaffoldMessengerKey: yuntaMessengerKey,
    title: 'Yunta',
    debugShowCheckedModeBanner: false,
    theme: YuntaTheme.light,
    routes: {'/notifications': (_) => const NotificationInboxScreen()},
    home: supabaseConfigured
        ? const SessionGate()
        : const ConfigurationScreen(),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<RegisteredProfile?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<RegisteredProfile?> _loadProfile() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return null;
    return ProfileRepository(client).getMyProfile();
  }

  void _registered(RegisteredProfile profile) => setState(() {
    _profile = Future.value(profile);
  });

  void _retry() => setState(() {
    _profile = _loadProfile();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<RegisteredProfile?>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.hasError) return ProfileLoadError(onRetry: _retry);
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingScreen();
      }
      final profile = snapshot.data;
      if (profile == null) {
        return RegistrationScreen(onRegistered: _registered);
      }
      return HomeScreen(profile: profile);
    },
  );
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(child: Center(child: CircularProgressIndicator())),
  );
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
              const YuntaWordmark(),
              const SizedBox(height: 28),
              Text(
                'Falta conectar Yunta',
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
              const YuntaWordmark(),
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
