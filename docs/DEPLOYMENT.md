# Configuración y publicación

## Supabase

El proyecto usa las migraciones de `supabase/migrations/` en orden cronológico. En un proyecto nuevo, ejecútalas una vez desde SQL Editor, verificando el resultado de cada consulta.

En **Authentication → Sign In / Providers**, habilita **Allow anonymous sign-ins**. La app conserva una sesión anónima en el celular. El teléfono se almacena de forma privada y no se verifica por SMS.

La clave que usa la app es la publicable (`sb_publishable_...` o la anon key legada). Va en `.env.json` como `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`. No uses `service_role`.

Las tablas privadas no dan acceso directo a los roles de API. Los RPCs publicados devuelven distancia redondeada y no exponen coordenadas exactas. RLS limita los mensajes a quienes tienen acceso vigente al caso. No actives la exposición automática de tablas nuevas.

## APK

`./scripts/build-apk.ps1` lee `.env.json` y deja el paquete de prueba en `artifacts/Yunta.apk`. Esa compilación se firma con la clave de depuración.

## Migraciones futuras

Agrega un archivo SQL nuevo con prefijo de fecha, mantén cada archivo bajo 400 líneas y pide la revisión independiente de código y especificación indicada en `AGENTS.md`. Aplica el archivo una sola vez en Supabase y confirma el resultado antes de publicar una app que dependa de él.
