import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/yunta_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  } catch (_) {}
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  final hasClientConfig = url.startsWith('https://') && key.isNotEmpty;
  var configured = false;
  if (hasClientConfig) {
    try {
      await Supabase.initialize(url: url, publishableKey: key);
      configured = true;
    } catch (_) {}
  }
  runApp(YuntaApp(supabaseConfigured: configured));
}
