import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'data/offline_yunta.dart';
import 'data/prefs_store.dart';
import 'data/supabase_yunta.dart';
import 'screens/enter_page.dart';
import 'screens/wall_page.dart';
import 'theme.dart';

/// Arranque.
/// La URL y la anon key entran en compilación, nunca la service role:
/// flutter run --dart-define-from-file=env.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(const SetupApp());
    return;
  }
  await Supabase.initialize(
    url: url,
    publishableKey: key,
    // Apagado también en depuración: el cliente de auth escribe la sesión si está en true.
    debug: false,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  final prefs = await SharedPreferences.getInstance();
  final store = PrefsStore(prefs);
  final api = OfflineYunta(SupabaseYunta(Supabase.instance.client), store);
  final app = AppState(api, store);
  runApp(YuntaRoot(app: app));
}

class YuntaRoot extends StatefulWidget {
  const YuntaRoot({super.key, required this.app});
  final AppState app;

  @override
  State<YuntaRoot> createState() => _YuntaRootState();
}

class _YuntaRootState extends State<YuntaRoot> with WidgetsBindingObserver {
  void Function()? _unwatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.app.refresh();
    _unwatch = widget.app.api.watchSession(() => widget.app.refresh());
    widget.app.addListener(_rebuild);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unwatch?.call();
    widget.app.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Al volver a primer plano se reintentan los avisos y mensajes en cola.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.app.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return MaterialApp(
      title: 'Yunta',
      theme: yuntaTheme(),
      home: app.booting
          ? const Scaffold(body: Center(child: Text('Abriendo Yunta…')))
          : app.session == null
              ? EnterPage(app: app)
              : WallPage(app: app),
    );
  }
}

class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: yuntaTheme(),
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Falta conectar Yunta.\n\n'
            'Copia env.example.json a env.json con la URL y la anon key, '
            'y arranca con flutter run --dart-define-from-file=env.json.\n\n'
            'Usa la anon key. La service role no va en la app.',
          ),
        ),
      ),
    );
  }
}
