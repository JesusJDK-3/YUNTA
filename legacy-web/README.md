# Yunta

Yunta es una PWA vecinal para encontrar ayuda, compartir productos y servicios, y coordinar apoyo ante emergencias cerca de casa.

## Stack

- React y Vite; interfaz adaptable a móvil y escritorio.
- Supabase Auth anónimo, PostgreSQL con PostGIS, RLS y Realtime.
- Service worker precargado e IndexedDB para avisos pendientes sin conexión.
- GitHub y Vercel para versiones y publicación HTTPS.

## Ejecutar en local

1. Instala Node.js 20.19+ o 22.12+.
2. Ejecuta `npm install`.
3. Copia `.env.example` a `.env` y agrega la URL y la clave publicable de Supabase.
4. Ejecuta `npm run dev`.

Las variables `VITE_*` son públicas. Nunca guardes claves `service_role` ni la contraseña de la base de datos en el cliente o en GitHub.

## Base de datos y despliegue

La especificación funcional está en [`docs/ESPECIFICACION.md`](docs/ESPECIFICACION.md). Las migraciones están en `supabase/migrations/`; la guía para aplicarlas y publicar está en [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

Todos los archivos de código fuente deben mantenerse en un máximo de 400 líneas. Los revisores del proyecto y sus reglas están definidos en `AGENTS.md` y `.cursor/agents/`.
