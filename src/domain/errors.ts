/**
 * Errores de dominio con un código estable.
 * La interfaz traduce el código a una frase. El texto crudo de Postgres
 * no llega a la pantalla.
 */

export class YuntaError extends Error {
  readonly code: string;

  constructor(code: string, message?: string) {
    super(message ?? messageFor(code));
    this.name = "YuntaError";
    this.code = code;
  }
}

const MESSAGES: Record<string, string> = {
  unauthenticated: "Entra de nuevo para continuar.",
  profile_required: "Falta tu nombre y tu zona.",
  validation: "Revisa los datos. Hay algún campo demasiado corto o demasiado largo.",
  forbidden: "No puedes hacer eso en este aviso.",
  not_found: "Ese aviso ya no está.",
  conflict: "Esa acción ya estaba hecha.",
  rate_limit: "Vas muy rápido. Espera un momento y vuelve a intentar.",
  location_required: "Para ver emergencias cercanas, permite la ubicación o elige tu zona.",
  slot_taken: "Ya hay alguien en esta coordinación.",
  chat_closed: "Este chat ya no recibe mensajes.",
  self_action: "No puedes hacerte eso a ti mismo.",
  blocked: "Esa coordinación no está disponible.",
  zone_mismatch: "El visto bueno es entre vecinos de la misma zona.",
  private_text: "No publiques celulares ni direcciones exactas. Compártelos en el chat.",
  network: "Sin conexión. El aviso quedó en este celular y se enviará al volver la señal.",
  unexpected: "Algo falló. Inténtalo otra vez.",
};

export function messageFor(code: string): string {
  return MESSAGES[code] ?? MESSAGES.unexpected;
}

/** Traduce el mensaje `YUNTA:codigo` que lanzan las funciones SQL. */
export function fromRemoteMessage(raw: string): YuntaError {
  const match = /YUNTA:([a-z_]+)/.exec(raw);
  const code = match?.[1] ?? (isNetworkMessage(raw) ? "network" : "unexpected");
  return new YuntaError(code);
}

export function isNetworkMessage(raw: string): boolean {
  const text = raw.toLowerCase();
  return (
    text.includes("failed to fetch") ||
    text.includes("network") ||
    text.includes("load failed") ||
    text.includes("offline")
  );
}

export function asYuntaError(error: unknown): YuntaError {
  if (error instanceof YuntaError) return error;
  if (error instanceof TypeError && isNetworkMessage(error.message)) {
    return new YuntaError("network");
  }
  if (error instanceof Error) return fromRemoteMessage(error.message);
  return new YuntaError("unexpected");
}
