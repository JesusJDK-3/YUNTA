import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/yunta_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  final configured = url.startsWith('https://') && key.isNotEmpty;

  if (configured) {
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(YuntaApp(supabaseConfigured: configured));
}
