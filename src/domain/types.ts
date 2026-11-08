/**
 * Contratos que ve la interfaz.
 * El punto geográfico no está en estos tipos: la pantalla recibe zona
 * y una frase de distancia ya redondeada.
 */

export const ZONES = [
  { id: "norte", name: "Zona Norte" },
  { id: "centro", name: "Zona Centro" },
  { id: "sur", name: "Zona Sur" },
  { id: "este", name: "Zona Este" },
] as const;

export type ZoneId = (typeof ZONES)[number]["id"];

export const HELP_TYPES = [
  "herramienta",
  "ayuda_temporal",
  "donacion",
  "habilidad",
  "movilidad",
] as const;

export type HelpType = (typeof HELP_TYPES)[number];

export const INTENTS = [
  "pido_ayuda",
  "ofrezco_ayuda",
  "producto",
  "servicio",
  "emergencia_persona",
  "emergencia_cuadra",
  "emergencia_recurso",
  "grupo_apoyo",
] as const;

export type Intent = (typeof INTENTS)[number];

export type Kind = "anuncio" | "caso";
export type CoordinationMode = "individual" | "grupal";
export type MemberRole = "prestador" | "receptor" | "participante";
export type MemberStatus = "pendiente" | "aceptado" | "retirado";

export type FeedTab = "ayuda" | "servicios" | "emergencias";

export interface Session {
  userId: string;
  displayName: string;
  zoneId: ZoneId;
  zoneName: string;
}

export interface FeedItem {
  id: string;
  kind: Kind;
  category: string;
  type: string;
  title: string;
  description: string;
  zoneId: ZoneId;
  zoneName: string;
  areaLabel: string;
  /** Frase ya redondeada. Nunca metros exactos. */
  distanceLabel: string | null;
  coordinationMode: CoordinationMode | null;
  status: string;
  recommendationCount: number;
  /** Presente solo cuando el prestador acumula 3 valoraciones o más. */
  ratingAverage: number | null;
  ratingCount: number;
  authorId: string;
  authorName: string;
  sourceAnuncioId: string | null;
  createdAt: string;
}

export interface MemberView {
  userId: string;
  displayName: string;
  role: MemberRole;
  status: MemberStatus;
}

export interface MessageView {
  id: string;
  senderId: string;
  senderName: string;
  body: string;
  createdAt: string;
  /** Escrito sin señal. Se envía cuando vuelve la red. */
  pending?: boolean;
}

export interface Detail {
  item: FeedItem;
  /** Compañeros aceptados. Vacío si quien mira no participa. */
  members: MemberView[];
  /** Solicitudes que esta persona puede aceptar o rechazar. */
  pending: MemberView[];
  messages: MessageView[];
  myRole: MemberRole | null;
  myStatus: MemberStatus | null;
  isAuthor: boolean;
  chatOpen: boolean;
  canSend: boolean;
  canRecommend: boolean;
  alreadyRecommended: boolean;
  canOfferHelp: boolean;
  canRequestHelp: boolean;
  canJoinGroup: boolean;
  canResolve: boolean;
  canCancel: boolean;
  canReopen: boolean;
  canSharePhone: boolean;
  canEdit: boolean;
  canRetire: boolean;
  canRate: boolean;
  myRating: { score: number; comment: string } | null;
  /** La ficha salió de la copia guardada en el celular. */
  offline?: boolean;
}

export interface PublishInput {
  intent: Intent;
  helpType?: HelpType;
  title: string;
  description: string;
  areaLabel?: string;
  /** Punto aproximado. El servidor lo guarda y no lo devuelve. */
  lat?: number;
  lng?: number;
  clientRequestId: string;
}

export interface BlockView {
  userId: string;
  displayName: string;
}

export interface FeedResult {
  items: FeedItem[];
  /** Falta el GPS: el muro de emergencias solo muestra grupos de apoyo. */
  needsLocation: boolean;
  /** La lista salió de la copia guardada en el celular. */
  offline?: boolean;
}
