# Especificación funcional de Yunta

Esta especificación resume de forma versionable el documento fuente `YUNTA.docx`. El producto es una aplicación vecinal móvil que conecta a personas cercanas para pedir u ofrecer ayuda, encontrar productos y servicios recomendados y coordinar apoyo ante emergencias.

## Problema y objetivo

En un mismo barrio, una persona puede necesitar una muleta prestada, buscar un gasfitero de confianza o pedir apoyo porque la lluvia inundó su cuadra. Alguien próximo quizá tenga el recurso, conozca a un profesional o pueda ayudar. Hoy la información queda dispersa entre contactos y grupos de mensajes, los avisos se pierden y es difícil saber quién ya atiende cada caso. La app debe facilitar préstamos, donaciones, intercambios, servicios cercanos y coordinación de emergencias, incluso con conexión intermitente.

Cada barrio cuenta con un muro de publicaciones. El vecino puede pedir u ofrecer ayuda, publicar productos o servicios con recomendaciones vecinales y reportar emergencias. Para participar, abre el aviso y elige la acción de coordinación que corresponda.

## Vistas y recorridos

### Registro y zona

- Solicitar nombre visible y número de celular real. Validar el formato; el número es privado y el SMS está deshabilitado durante la demo.
- Solicitar la ubicación con GPS o permitir marcar un punto aproximado en el mapa. El registro no solicita ni guarda un nombre de barrio; las categorías clasifican las publicaciones y la distancia se calcula con la ubicación.
- Mostrar un tutorial breve al entrar por primera vez, con instrucciones para publicar y sumarse a un caso.
- Crear una sesión anónima persistente de Supabase en Android. La sesión identifica al vecino.

### Muro

- Presentar las secciones Ayuda, Productos y servicios, y Emergencias, más un botón visible Publicar.
- Filtrar las tres secciones a 500 m desde la ubicación del vecino. Un aviso cercano puede aparecer aunque pertenezca a otro barrio; el nombre de barrio orienta, pero no reemplaza el filtro por distancia.
- Cada aviso conserva su propia ubicación, que puede diferir de la ubicación del autor. Mostrar distancia y zona aproximadas; no mostrar coordenadas exactas.
- Cada tarjeta presenta título, distancia aproximada y estado, además de si la coordinación es individual o grupal.
- El flujo de publicación debe requerir tres acciones principales desde el muro: Publicar, elegir el tipo y enviar. Descripción y modalidad van en el mismo formulario.
- Emergencias llevan un ícono y una etiqueta en rojo ladrillo.

El documento fuente incluye un ejemplo hipotético con radio de 1 km. La regla definida para la app y para su arquitectura es 500 m.

### Detalle y coordinación

- Mostrar descripción, estado del caso y una acción según modalidad: Puedo ayudar o Unirme a la coordinación.
- La modalidad individual permite que vecinos se ofrezcan; el autor acepta a una sola persona a la vez y abre un chat privado con ella. La base de datos garantiza que solo una persona quede aceptada a la vez. Puede reabrir el caso para buscar a otra persona.
- Al reabrir un caso individual, la base de datos libera la asignación anterior y devuelve el aviso a Abierto en la misma operación. La persona anterior pierde acceso al chat.
- En modalidad grupal, quienes se unen participan en el mismo chat del caso, pueden repartirse tareas y confirmar recursos. Cada caso grupal tiene un chat separado.
- Si necesitan compartir una dirección exacta, los vecinos pueden hacerlo durante la coordinación; el muro continúa mostrando solo una ubicación aproximada.
- El autor puede editar o retirar su anuncio de producto o servicio. Al resolver un caso individual, quien recibió la ayuda puede dejar una valoración opcional al proveedor; normalmente será el autor en una solicitud de ayuda, pero no necesariamente en un anuncio de servicio.

## Modalidades y estados

| Elemento | Regla |
| --- | --- |
| Individual | Una persona aceptada a la vez; quienes ofrecen ayuda quedan pendientes hasta que el autor elija. Chat privado entre autor y persona aceptada. |
| Grupal | Participantes activos comparten un chat ligado al caso. La combinación caso y vecino evita duplicados. |
| Abierto | Se puede ofrecer ayuda individual o unirse al grupo. |
| En coordinación | El autor aceptó a una persona o al menos una persona se sumó al grupo. |
| Resuelto | El autor cerró el caso; el chat queda disponible para consulta y puede habilitarse una valoración individual. |
| Cancelado | Se retiran nuevas participaciones y mensajes. |
| Pendiente de envío | Estado local de un aviso creado sin conexión. No se muestra a otros hasta que Supabase confirme su guardado. |

Los reintentos de envío conservan el mismo identificador del aviso para evitar duplicados. La sincronización se realiza al recuperar internet mientras la app está abierta. El chat en vivo requiere conexión.

## Datos y arquitectura

| Capa | Tecnología y responsabilidad |
| --- | --- |
| Interfaz móvil | Flutter para Android; registro, muro cercano, detalle y chat con la paleta Yunta. |
| Sesión | Supabase Auth anónimo con almacenamiento persistente de la sesión. Durante la demo no se envían SMS. |
| Base de datos | Supabase con PostgreSQL; perfiles, publicaciones, participantes, mensajes, recomendaciones y valoraciones. |
| Ubicación | Permiso GPS de Android en primer plano y consulta por distancia en PostgreSQL. El radio vigente es 500 m; coordenadas exactas se usan para calcular, no se muestran. |
| Chat | Supabase Realtime, con persistencia en base de datos y políticas RLS para autor y participantes autorizados. |
| Modo sin conexión | Almacenamiento privado de Android. Después de abrir una vez con internet, permitir dejar avisos pendientes y sincronizarlos al volver la conexión mientras la app permanece abierta. No usar caché pública. |
| Distribución | Repositorio GitHub con commits por hito y APK compilable con Flutter/Gradle y Android Studio. Supabase usa solo URL y publishable key de cliente; nunca se incluye una service-role key. |

## Modelo de datos

Las tablas de usuario se relacionan con `auth.users.id` mediante `user_id`.

| Tabla | Campos principales | Uso y reglas |
| --- | --- | --- |
| `profiles` | `user_id`, `display_name`, `created_at`, `updated_at` | Perfil visible. El vecino edita su nombre; otros lo ven en publicaciones, recomendaciones y mensajes. |
| `private_profiles` | `user_id`, `phone_e164`, `phone_verified_at`, `latitude`, `longitude`, `location_source`, `updated_at` | Teléfono real y ubicación personal, editables por su titular. El teléfono solo lo consulta su titular desde la app. Durante la demo, `phone_verified_at` queda vacío porque SMS está deshabilitado. |
| `user_settings` | `user_id`, `tutorial_completed_at` | Preferencias personales utilizadas por la app, como si se completó el tutorial. El radio de 500 m es regla de consulta, no una preferencia personal. |
| `posts` | `id`, `author_id`, `category`, `type`, `title`, `description`, `coordination_mode`, `status`, `latitude`, `longitude`, `area_label`, `created_at`, `updated_at`, `closed_at` | Avisos de ayuda, productos/servicios y emergencias. Cada aviso tiene ubicación propia y modalidad individual o grupal. Solo el autor modifica, resuelve, cancela o reabre cuando corresponde. Puede editar o retirar su anuncio de producto o servicio. |
| `post_members` | `post_id`, `user_id`, `role`, `status`, `joined_at`, `updated_at` | Autor y vecinos participantes. En modo individual diferencia ofertas pendientes de la persona aceptada; en modo grupal registra participantes. |
| `messages` | `id`, `post_id`, `sender_id`, `body`, `created_at` | Historial de chat asociado a un caso. Realtime lo entrega a participantes conectados. RLS limita lectura y envío al autor y participantes con acceso. |
| `recommendations` | `post_id`, `user_id`, `created_at` | Vecino que recomienda un anuncio de producto o servicio. Cada vecino recomienda un anuncio como máximo una vez. |
| `ratings` | `id`, `post_id`, `reviewer_id`, `reviewed_user_id`, `score`, `comment`, `created_at` | Valoración opcional del proveedor por parte de quien recibió la ayuda o servicio. Una por caso; nota de 1 a 5 y comentario opcional. |

Los tipos de publicación se agrupan así:

| Categoría | Tipos |
| --- | --- |
| Ayuda | Solicitud de ayuda, oferta de ayuda |
| Productos y servicios | Producto, servicio |
| Emergencias | Solicitud urgente, recurso disponible, grupo de apoyo disponible |

En un caso individual deben distinguirse receptor y proveedor por separado del autor del aviso cuando sea necesario. `reviewer_id` identifica al receptor que deja la valoración; `reviewed_user_id` identifica a quien prestó la ayuda o servicio. Solo el receptor valora después de resolver. Si el servicio proviene de un anuncio, la valoración corresponde a esa atención concreta; recomendar el anuncio sigue siendo una acción separada.

## Permisos y privacidad

- Cada vecino edita su nombre, teléfono, ubicación y preferencias; los datos privados solo son consultables por su titular desde la app.
- La búsqueda devuelve avisos dentro de 500 m. Las coordenadas exactas se usan en el cálculo; el muro muestra zona y distancia aproximadas.
- Solo el autor puede modificar, resolver, cancelar o reabrir su publicación.
- Solo el autor y participantes con acceso vigente leen o envían mensajes. Las reglas deben aplicarse en Supabase con RLS, no solo ocultando controles en la interfaz.
- Quien recibió la ayuda o servicio califica a quien lo prestó; esa persona no necesariamente es el autor del aviso.
- No guardar teléfono, coordenadas exactas, contenido de mensajes ni datos de perfil en almacenamiento público o compartido del dispositivo.

## Diseño visual original del Word

| Color | HEX | Aplicación |
| --- | --- | --- |
| Crema cálida | `#FFF7E8` | Fondo de registro, muro y chat; también texto sobre botones azules. |
| Azul petróleo | `#245062` | Títulos, texto, íconos y burbujas propias. |
| Durazno dorado | `#F2B476` | Logo, bienvenida e ilustraciones del tutorial. |
| Durazno vivo | `#F6A754` | Acción principal Publicar, con texto azul petróleo. |
| Azul petróleo vivo | `#1B5C76` | Botón Puedo ayudar y pestaña activa. |
| Rojo ladrillo suave | `#A13D42` | Etiqueta Emergencia con ícono. |

La referencia visual original es [Campsite en Refero](https://styles.refero.design/style/5d8ad116-b3d8-4890-a969-5b856b35c678). Su paleta crema y durazno fue reemplazada para la interfaz vigente por la decisión del usuario siguiente; los requisitos funcionales del Word siguen vigentes.

## Actualización visual aprobada el 7 de noviembre de 2026

- Usar blanco `#FFFFFF` como fondo principal de la app Android.
- Conservar azul petróleo para texto e identidad; mantener el logotipo actual con la letra Y, sin sustituirlo por un corazón.
- Usar amarillo alegre y suave `#F3D76F` para acciones principales, con texto azul petróleo y hover `#EBCB5C`.
- Reservar amarillo pálido `#FFF3C5` para resaltados pequeños. Mantener rojo ladrillo para emergencias y verde para estados reales.
- Dar movimiento ambiental lento solo a formas decorativas detrás del encabezado. No mover texto ni datos; respetar `prefers-reduced-motion`.
- Conservar tarjetas legibles, con superficies blancas, bordes suaves y controles aptos para móvil.
