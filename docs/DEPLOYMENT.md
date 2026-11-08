# Configuración y publicación

## Supabase

El proyecto usa las migraciones de `supabase/migrations/` en orden cronológico. En un proyecto nuevo, ejecútalas una vez desde SQL Editor, verificando el resultado de cada consulta.

En **Authentication → Sign In / Providers**, habilita **Allow anonymous sign-ins**. Durante la demo se conserva una sesión anónima por navegador; borrar los datos del navegador o cerrar esa sesión elimina el acceso a ese perfil. El teléfono se almacena de forma privada y no se verifica por SMS.

Configura la URL permitida de Auth para el dominio de Vercel y, si se usa localmente, `http://localhost:5173`. La clave que usa el frontend es la publicable (`sb_publishable_...` o la anon key legada); no uses `service_role` en variables `VITE_*`.

Las tablas privadas no dan acceso directo a los roles de API. Los RPCs publicados devuelven distancia redondeada y no exponen coordenadas exactas. RLS limita los mensajes a quienes tienen acceso vigente al caso. No actives la exposición automática de tablas nuevas.

## Local y Vercel

Define estas variables tanto en `.env` local como en **Vercel → Project → Settings → Environment Variables**:

| Variable | Valor |
| --- | --- |
| `VITE_SUPABASE_URL` | URL HTTPS del proyecto Supabase |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Clave publicable del proyecto |

Asigna las variables a Production, Preview y Development según corresponda. Vercel usa `npm run build` y publica `dist/`; `vercel.json` mantiene las rutas de la aplicación.

## Migraciones futuras

Agrega un archivo SQL nuevo con prefijo de fecha, mantén cada archivo bajo 400 líneas y pide la revisión independiente de código y especificación indicada en `AGENTS.md`. Aplica el archivo una sola vez en Supabase y confirma el resultado antes de desplegar frontend que dependa de él.
