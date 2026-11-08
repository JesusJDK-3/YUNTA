# Notificaciones push Android

Yunta usa Firebase Cloud Messaging (FCM) para avisos push y Supabase Realtime para
actualizar el buzón mientras la app está abierta. FCM está disponible en el plan
Spark sin costo. Supabase Free incluye 500 000 invocaciones mensuales de Edge
Functions; la cuota se comparte con las demás funciones del proyecto.

## Flujo

1. Android solicita permiso antes de registrar la instalación. El auto-init de
FCM y Analytics permanece desactivado.
2. Con permiso concedido, Flutter registra el FID y lo guarda en `push_tokens`.
   RLS permite a cada usuario gestionar solo sus propios dispositivos.
3. El trigger de `notifications` inserta el aviso in-app. Un Database Webhook de
   Supabase envía los eventos `INSERT` a `send-yunta-push`.
4. La Edge Function autentica el webhook, consulta los FID del destinatario y
   envía un mensaje FCM genérico. No envía nombre, teléfono, ubicación ni texto
   del aviso.

## Configuración remota requerida

- En Firebase, registrar la aplicación Android `com.yunta.vecinal` y mantener
  el proyecto en Spark.
- En Google Cloud, usar una cuenta de servicio dedicada con el rol
  `Firebase Cloud Messaging API Admin`. La clave privada nunca se incluye en
  este repositorio.
- Desplegar `supabase/functions/send-yunta-push/index.ts`.
- Guardar en Edge Function Secrets `FIREBASE_SERVICE_ACCOUNT_JSON` y
  `PUSH_WEBHOOK_SECRET`. Supabase proporciona `SUPABASE_URL` y
  `SUPABASE_SERVICE_ROLE_KEY` a la función.
- Crear un Database Webhook para `public.notifications`, solo evento `INSERT`,
  destino `https://<project-ref>.supabase.co/functions/v1/send-yunta-push`.
  Enviar `Content-Type: application/json`, `apikey: <publishable key>` y
  `x-yunta-push-secret: <mismo secreto>`. El gateway valida `apikey` y la
  función valida el secreto propio del webhook.
- Mantener activada la verificación JWT de Supabase en la función y el control
  adicional del encabezado secreto en el código.

Después de conceder el permiso de notificaciones, reinstalar la APK si se cambió
la aplicación Firebase. El primer registro requiere conexión a internet.
