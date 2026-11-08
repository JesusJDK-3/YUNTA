# Yunta

Yunta es una aplicación Android nativa hecha con Flutter y Dart. Supabase gestiona la sesión anónima, PostgreSQL, RLS y Realtime. El antiguo sitio PWA se conserva en `legacy-web/`.

En esta copia también sigue la web (`src/`, `npm run dev`) y un cliente Flutter aparte en `app/`.

## Preparación

1. Instala Flutter y Android Studio con JDK 17.
2. Copia `supabase.defines.example.json` a `.env.json`.
3. En `.env.json`, coloca la URL y la publishable key del proyecto Supabase. Este archivo se excluye de Git; nunca uses una service-role key.
4. Ejecuta `flutter pub get`.

## Ejecutar y compilar

Abre el proyecto en Android Studio, o ejecuta `flutter run --dart-define-from-file=.env.json`. Para generar el APK en modo lanzamiento, ejecuta `./scripts/build-apk.ps1`. El archivo queda en `artifacts/Yunta.apk`.

La aplicación pide permiso de ubicación solo al usar el GPS. El punto elegido se guarda en el perfil privado de Supabase y nunca se muestra en pantalla. También se puede elegir un punto aproximado en el mapa.

## Web de esta copia

```bash
npm install
cp .env.example .env.local
npm test
npm run dev
```

Completa `.env.local` con la URL y la anon key antes de `npm run dev`. El cliente de `app/` usa `app/env.example.json` copiado a `app/env.json`.

## Hitos

- Registro: nombre, celular peruano privado y ubicación GPS o punto del mapa; sesión anónima persistente.
- Muro: publicaciones reales de Supabase dentro de 500 m, sin datos de ejemplo.
- Chat: mensajes persistidos y recibidos en tiempo real por Supabase Realtime.

Cada hito se revisa, compila y publica en GitHub antes de continuar con el siguiente.
