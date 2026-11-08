/**
 * Contrato único de la app.
 * Cada método llama una función de Supabase. Ninguno incluye latitud ni longitud.
 */

import type {
  BlockView,
  Detail,
  FeedResult,
  FeedTab,
  Session,
  ZoneId,
} from "../domain/types";

export interface ViewerPoint {
  lat: number;
  lng: number;
}

export interface YuntaApi {
  listZones(): Promise<{ id: ZoneId; name: string }[]>;
  currentSession(): Promise<Session | null>;
  /** Correo ya autenticado que todavía no eligió zona. */
  pendingEmail(): Promise<string | null>;
  requestMagicLink(email: string): Promise<void>;
  saveProfile(displayName: string, zoneId: string): Promise<Session>;
  signOut(): Promise<void>;
  takeNotice(): Promise<string | null>;
  feed(tab: FeedTab, point: ViewerPoint | null): Promise<FeedResult>;
  detail(id: string): Promise<Detail>;
  publish(input: unknown): Promise<{ id: string; deduped: boolean }>;
  coordinate(anuncioId: string, clientRequestId: string): Promise<{ id: string; deduped: boolean }>;
  requestEntry(casoId: string): Promise<void>;
  accept(casoId: string, userId: string): Promise<void>;
  reject(casoId: string, userId: string): Promise<void>;
  joinGroup(casoId: string): Promise<void>;
  removeMember(casoId: string, userId: string): Promise<void>;
  resolve(casoId: string): Promise<void>;
  cancel(id: string): Promise<void>;
  reopen(casoId: string): Promise<void>;
  retireAnuncio(id: string): Promise<void>;
  editAnuncio(id: string, title: string, description: string): Promise<void>;
  sendMessage(casoId: string, body: string): Promise<void>;
  recommend(anuncioId: string): Promise<void>;
  rate(casoId: string, score: number, comment: string): Promise<void>;
  report(targetType: "publicacion" | "mensaje", targetId: string, reason: string): Promise<void>;
  block(userId: string): Promise<void>;
  unblock(userId: string): Promise<void>;
  blocks(): Promise<BlockView[]>;
  sharePhone(casoId: string, phone: string): Promise<void>;
  /** Avisos guardados en el celular que todavía no confirmó el servidor. */
  pendingPublishes(): Promise<number>;
  flushPublishes(): Promise<number>;
  /** Avisa cuando entra un mensaje y la pantalla vuelve a pedir el detalle. */
  subscribeMessages(casoId: string, onChange: () => void): () => void;
  /** Avisa cuando la sesión de Supabase cambia (vuelta del enlace al correo). */
  watchSession(onChange: () => void): () => void;
}
