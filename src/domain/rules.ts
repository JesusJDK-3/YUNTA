/**
 * Reglas puras de Yunta.
 *
 * Un anuncio permanece publicado. Un caso es una coordinación con chat.
 * Quien califica es siempre el receptor, aunque no haya escrito el aviso.
 * La distancia que sale de aquí ya está redondeada: los metros exactos
 * sirven para ordenar y filtrar, y no se muestran.
 */

import { z } from "zod";
import { YuntaError } from "./errors";
import { HELP_TYPES, INTENTS, ZONES, type HelpType, type Intent, type PublishInput, type ZoneId } from "./types";

export const LIMITS = {
  nameMin: 2,
  nameMax: 40,
  titleMin: 3,
  titleMax: 80,
  descriptionMax: 500,
  messageMax: 500,
  commentMax: 280,
  areaMax: 40,
  reasonMax: 200,
  feedLimit: 40,
  postsPerHour: 8,
  messagesPerFiveMin: 30,
  emergencyRadiusM: 500,
  distanceStepM: 100,
  publicRatingMin: 3,
} as const;

export function zoneName(zoneId: string): string {
  return ZONES.find((zone) => zone.id === zoneId)?.name ?? zoneId;
}

export function isZoneId(value: string): value is ZoneId {
  return ZONES.some((zone) => zone.id === value);
}

/** Centros de las cuatro zonas. El GPS solo sugiere la más cercana. */
export const ZONE_CENTERS: Record<ZoneId, { lat: number; lng: number }> = {
  norte: { lat: -12.043, lng: -77.04 },
  centro: { lat: -12.05, lng: -77.04 },
  sur: { lat: -12.057, lng: -77.04 },
  este: { lat: -12.05, lng: -77.032 },
};

export interface PublishSpec {
  kind: "anuncio" | "caso";
  category: string;
  type: string;
  coordinationMode: "individual" | "grupal" | null;
  /** Papel de quien publica. Null en un anuncio: todavía no hay caso. */
  authorRole: "prestador" | "receptor" | "participante" | null;
  /** Estado inicial del caso. El anuncio nace activo. */
  initialStatus: string;
}

/**
 * Una sola tabla de decisión para la interfaz y el SQL.
 * Si se agrega un intento, hay que tocarla aquí y en la migración.
 */
export function specFromIntent(intent: Intent, helpType?: HelpType): PublishSpec {
  switch (intent) {
    case "pido_ayuda":
      return {
        kind: "caso",
        category: "ayuda",
        type: helpType ?? "ayuda_temporal",
        coordinationMode: "individual",
        authorRole: "receptor",
        initialStatus: "abierto",
      };
    case "ofrezco_ayuda":
      return {
        kind: "caso",
        category: "ayuda",
        type: helpType ?? "ayuda_temporal",
        coordinationMode: "individual",
        authorRole: "prestador",
        initialStatus: "abierto",
      };
    case "producto":
      return {
        kind: "anuncio",
        category: "producto",
        type: "producto",
        coordinationMode: null,
        authorRole: null,
        initialStatus: "activo",
      };
    case "servicio":
      return {
        kind: "anuncio",
        category: "servicio",
        type: "servicio",
        coordinationMode: null,
        authorRole: null,
        initialStatus: "activo",
      };
    case "emergencia_persona":
      return {
        kind: "caso",
        category: "emergencia",
        type: "persona",
        coordinationMode: "individual",
        authorRole: "receptor",
        initialStatus: "abierto",
      };
    case "emergencia_cuadra":
      return {
        kind: "caso",
        category: "emergencia",
        type: "cuadra",
        coordinationMode: "grupal",
        authorRole: "participante",
        initialStatus: "abierto",
      };
    case "emergencia_recurso":
      return {
        kind: "caso",
        category: "emergencia",
        type: "recurso",
        coordinationMode: "grupal",
        authorRole: "participante",
        initialStatus: "abierto",
      };
    case "grupo_apoyo":
      return {
        kind: "anuncio",
        category: "grupo_de_apoyo",
        type: "grupo_de_apoyo",
        coordinationMode: null,
        authorRole: null,
        initialStatus: "activo",
      };
    default: {
      const neverIntent: never = intent;
      throw new YuntaError("validation", `Intento desconocido: ${String(neverIntent)}`);
    }
  }
}

const publishSchema = z.object({
  intent: z.enum(INTENTS),
  helpType: z.enum(HELP_TYPES).optional(),
  title: z.string(),
  description: z.string(),
  areaLabel: z.string().optional(),
  lat: z.number().optional(),
  lng: z.number().optional(),
  clientRequestId: z.string().uuid(),
});

export function parsePublish(input: unknown): PublishInput {
  const parsed = publishSchema.safeParse(input);
  if (!parsed.success) throw new YuntaError("validation");

  const title = cleanText(parsed.data.title, LIMITS.titleMax);
  const description = cleanText(parsed.data.description, LIMITS.descriptionMax);
  const areaLabel = parsed.data.areaLabel
    ? cleanText(parsed.data.areaLabel, LIMITS.areaMax)
    : undefined;

  if (title.length < LIMITS.titleMin) throw new YuntaError("validation");
  if (
    (parsed.data.intent === "pido_ayuda" || parsed.data.intent === "ofrezco_ayuda") &&
    !parsed.data.helpType
  ) {
    throw new YuntaError("validation");
  }

  assertCoords(parsed.data.lat, parsed.data.lng);
  assertPublicText(title, description, areaLabel);

  return {
    intent: parsed.data.intent,
    helpType: parsed.data.helpType,
    title,
    description,
    areaLabel: areaLabel || undefined,
    lat: parsed.data.lat,
    lng: parsed.data.lng,
    clientRequestId: parsed.data.clientRequestId,
  };
}

export function parseName(value: string): string {
  const name = cleanText(value, LIMITS.nameMax);
  if (name.length < LIMITS.nameMin) throw new YuntaError("validation");
  return name;
}

export function parseZone(value: string): ZoneId {
  if (!isZoneId(value)) throw new YuntaError("validation");
  return value;
}

export function parseMessage(value: string): string {
  const body = cleanText(value, LIMITS.messageMax);
  if (!body) throw new YuntaError("validation");
  return body;
}

export function parseReason(value: string): string {
  const reason = cleanText(value, LIMITS.reasonMax);
  if (reason.length < 3) throw new YuntaError("validation");
  return reason;
}

export function parseComment(value: string): string {
  return cleanText(value, LIMITS.commentMax);
}

export function parseScore(value: number): number {
  if (!Number.isInteger(value) || value < 1 || value > 5) throw new YuntaError("validation");
  return value;
}

/**
 * Acepta un celular de 8 a 15 dígitos, con o sin +.
 * No exige un país: el reto no está atado a una operadora.
 */
export function parsePhone(value: string): string {
  const compact = value.trim().replace(/[\s()-]/g, "");
  if (!/^\+?[0-9]{8,15}$/.test(compact)) throw new YuntaError("validation");
  return compact.startsWith("+") ? compact : `+${compact}`;
}

export function assertCoords(lat?: number, lng?: number): void {
  const hasLat = lat !== undefined;
  const hasLng = lng !== undefined;
  if (hasLat !== hasLng) throw new YuntaError("validation");
  if (lat === undefined || lng === undefined) return;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) throw new YuntaError("validation");
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) throw new YuntaError("validation");
}

/**
 * El muro es público. Un celular o una calle con número se dicen en el chat,
 * donde solo están quienes participan. La idea viene del avance de registro
 * del equipo y aquí protege el anuncio y el caso.
 */
const PRIVATE_PHONE = /(?:\+?\d[\d\s().-]{7,}\d)/;
const PRIVATE_STREET =
  /\b(?:calle|avenida|av\.?|jr\.?|jir[oó]n|manzana|mz\.?|lote|pasaje|psje|departamento|dpto)\b[^.\n]{0,40}\d{1,5}|\b\d{1,5}\s+(?:calle|avenida|av\.?|jr\.?|jir[oó]n|pasaje)\b/i;

export function assertPublicText(title: string, description: string, areaLabel?: string): void {
  const visible = `${title}\n${description}`;
  if (PRIVATE_PHONE.test(visible) || PRIVATE_STREET.test(visible)) {
    throw new YuntaError("private_text");
  }
  if (areaLabel && PRIVATE_STREET.test(areaLabel)) throw new YuntaError("private_text");
}

/** Quita controles y recorta. React escapa el texto; aquí solo normalizamos. */
export function cleanText(value: string, max: number): string {
  const withoutControls = value.normalize("NFC").replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, "");
  return withoutControls.trim().slice(0, max);
}

/**
 * Redondeo a 100 m. Por debajo de 100 m no decimos "0 m":
 * esa precisión, repetida, ayuda a triangular una casa.
 */
export function distanceLabel(meters: number | null): string | null {
  if (meters === null || !Number.isFinite(meters) || meters < 0) return null;
  if (meters < LIMITS.distanceStepM) return "A menos de 100 m";
  const rounded = Math.round(meters / LIMITS.distanceStepM) * LIMITS.distanceStepM;
  return `A unos ${rounded} m`;
}

export function haversineMeters(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const earth = 6_371_000;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * earth * Math.asin(Math.min(1, Math.sqrt(h)));
}

function toRad(value: number): number {
  return (value * Math.PI) / 180;
}

/** Zona sugerida: el centro más cercano. La persona igual tiene que confirmarla. */
export function nearestZone(lat: number, lng: number): ZoneId {
  assertCoords(lat, lng);
  let best: ZoneId = "centro";
  let bestMeters = Number.POSITIVE_INFINITY;
  for (const zone of ZONES) {
    const meters = haversineMeters({ lat, lng }, ZONE_CENTERS[zone.id]);
    if (meters < bestMeters) {
      best = zone.id;
      bestMeters = meters;
    }
  }
  return best;
}

export function withinHour(iso: string, nowMs: number): boolean {
  return nowMs - Date.parse(iso) < 60 * 60 * 1000;
}

export function withinFiveMinutes(iso: string, nowMs: number): boolean {
  return nowMs - Date.parse(iso) < 5 * 60 * 1000;
}

/**
 * La nota pública aparece desde la tercera valoración.
 * Antes de eso el conteo existe, pero el promedio no sale del servidor
 * hacia quien mira el muro.
 */
export function publicRating(count: number, average: number | null): {
  ratingCount: number;
  ratingAverage: number | null;
} {
  // El conteo también se esconde: "2 valoraciones" ya deja ver una nota suelta.
  if (count < LIMITS.publicRatingMin || average === null) {
    return { ratingCount: 0, ratingAverage: null };
  }
  return { ratingCount: count, ratingAverage: Math.round(average * 10) / 10 };
}
