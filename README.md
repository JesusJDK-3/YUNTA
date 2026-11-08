# Yunta Android

Yunta es una aplicación Android nativa hecha con Flutter y Dart. Supabase gestiona la sesión anónima, PostgreSQL, RLS y Realtime. El antiguo sitio PWA se conserva en `legacy-web/`.

## Preparación

1. Instala Flutter y Android Studio con JDK 17.
2. Copia `supabase.defines.example.json` a `.env.json`.
3. En `.env.json`, coloca la URL y la publishable key del proyecto Supabase. Este archivo se excluye de Git; nunca uses una service-role key.
4. Ejecuta `flutter pub get`.

## Ejecutar y compilar

Abre el proyecto en Android Studio, o ejecuta `flutter run --dart-define-from-file=.env.json`. Para generar un APK de depuración, ejecuta `./scripts/build-apk.ps1`. El archivo queda en `artifacts/Yunta-debug.apk`.

La aplicación pide permiso de ubicación solo al usar el GPS. El punto elegido se guarda en el perfil privado de Supabase y nunca se muestra en pantalla. También se puede elegir un punto aproximado en el mapa.

## Hitos

- Registro: nombre, celular peruano privado y ubicación GPS o punto del mapa; sesión anónima persistente.
- Muro: publicaciones reales de Supabase dentro de 500 m, sin datos de ejemplo.
- Chat: mensajes persistidos y recibidos en tiempo real por Supabase Realtime.

Cada hito se revisa, compila y publica en GitHub antes de continuar con el siguiente.
