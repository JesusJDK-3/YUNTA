# Yunta

Web del barrio para oficios, favores y emergencias. Un anuncio queda publicado. Un caso es una coordinación, con su propio chat.

La app solo funciona con Supabase. El correo de acceso, las zonas, el muro y el chat viven en ese proyecto.

## Preparar este computador

```bash
npm install
cp .env.example .env.local
npm test
npm run dev
```

Completa `.env.local` con la URL y la anon key antes de `npm run dev`.

## Base

1. Crea un proyecto en Supabase.
2. En el SQL Editor, ejecuta en orden `supabase/migrations/001_yunta.sql`, `002_yunta_actions.sql` y `003_yunta_detalle.sql`.
3. En Authentication, deja activo el proveedor Email y el enlace mágico. Desactiva el teléfono.
4. En Authentication → URL Configuration, pon la dirección pública de la web como Site URL y como Redirect URL. En local también agrega `http://127.0.0.1:5173`.
5. En los centros de `zones`, dentro de la primera migración, usa los puntos reales del barrio antes de que entre el primer vecino.
6. Copia la Project URL y la anon key a `.env.local`. En Vercel, las mismas variables van en Settings → Environment Variables. Vuelve a desplegar después de guardarlas.

La anon key es pública. La protección está en las funciones SQL: no devuelven coordenadas, el chat solo lo leen quienes están aceptados y el visto bueno exige la misma zona. La service role no se usa en esta web.

Los reportes se leen en el panel de Supabase, con la service role, no con la anon key.

## Qué cubre

- Directorio de productos y oficios, con visto bueno de la misma zona.
- Muro de ayuda: herramienta, ayuda temporal, donación, habilidad y movilidad.
- Emergencias a 500 metros, y grupos de apoyo de la zona.
- Caso entre dos, con aceptación, y caso en grupo para una cuadra.
- Valoración del receptor al prestador, visible desde la tercera nota.
- Reportar, bloquear y compartir el número solo dentro del chat.
- Aviso pendiente de envío si se corta la red, reutilizado con el mismo identificador.
- El muro rechaza un celular o una calle con número. Eso se comparte en el chat.
