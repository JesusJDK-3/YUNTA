/**
 * Cliente de Supabase.
 * La pantalla no arma SQL. Cada acción es una función con SECURITY DEFINER
 * y no devuelve el punto.
 */

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { fromRemoteMessage, YuntaError } from "../domain/errors";
import {
  parseAnnouncement,
  parseComment,
  parseEmail,
  parseMessage,
  parseName,
  parsePhone,
  parsePublish,
  parseReason,
  parseScore,
  parseZone,
} from "../domain/rules";
import type { BlockView, FeedTab } from "../domain/types";
import type { ViewerPoint, YuntaApi } from "./api";
import { parseDetail, parseFeed, parseSession } from "./parse";

export function createSupabaseApi(url: string, anonKey: string): YuntaApi {
  const client = createClient(url, anonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      // PKCE evita que el enlace del correo viaje con el token en el fragmento.
      flowType: "pkce",
      // El cliente de auth no escribe la sesión en la consola.
      debug: false,
    },
  });

  async function call<T>(fn: string, args: Record<string, unknown> = {}): Promise<T> {
    const { data, error } = await client.rpc(fn, args);
    if (error) throw fromRemoteMessage(`${error.message} ${error.details ?? ""}`);
    return data as T;
  }

  const api: YuntaApi = {
    async listZones() {
      const rows = await call<{ id: string; name: string }[]>("listar_zonas");
      return (rows ?? []).flatMap((row) => {
        try {
          return [{ id: parseZone(row.id), name: row.name }];
        } catch {
          return [];
        }
      });
    },

    async currentSession() {
      const user = await authUser(client);
      if (!user) return null;
      return parseSession(await call("mi_perfil"));
    },

    async pendingEmail() {
      const user = await authUser(client);
      if (!user) return null;
      const profile = parseSession(await call("mi_perfil"));
      return profile ? null : user.email ?? null;
    },

    async requestMagicLink(email: string) {
      const parsed = parseEmail(email);
      const { error } = await client.auth.signInWithOtp({
        email: parsed,
        options: { emailRedirectTo: window.location.origin },
      });
      if (error) throw fromRemoteMessage(error.message);
    },

    async saveProfile(displayName: string, zoneId: string) {
      await call("guardar_perfil", {
        p_name: parseName(displayName),
        p_zone_id: parseZone(zoneId),
      });
      const session = parseSession(await call("mi_perfil"));
      if (!session) throw new YuntaError("profile_required");
      return session;
    },

    async signOut() {
      const { error } = await client.auth.signOut();
      if (error) throw fromRemoteMessage(error.message);
    },

    async takeNotice() {
      return null;
    },

    async feed(tab: FeedTab, point: ViewerPoint | null) {
      return parseFeed(
        await call("feed_muro", {
          p_tab: tab,
          p_lat: point?.lat ?? null,
          p_lng: point?.lng ?? null,
        }),
      );
    },

    async detail(id: string) {
      return parseDetail(await call("detalle", { p_id: id }));
    },

    async publish(input: unknown) {
      // La validación ocurre antes de tocar la red.
      const parsed = parsePublish(input);
      return call<{ id: string; deduped: boolean }>("publicar", {
        p_intent: parsed.intent,
        p_help_type: parsed.helpType ?? null,
        p_title: parsed.title,
        p_description: parsed.description,
        p_area_label: parsed.areaLabel ?? null,
        p_lat: parsed.lat ?? null,
        p_lng: parsed.lng ?? null,
        p_client_request_id: parsed.clientRequestId,
      });
    },

    async coordinate(anuncioId: string, clientRequestId: string) {
      return call<{ id: string; deduped: boolean }>("coordinar", {
        p_anuncio_id: anuncioId,
        p_client_request_id: clientRequestId,
      });
    },

    requestEntry: (casoId) => call("pedir_entrada", { p_caso_id: casoId }),
    accept: (casoId, userId) => call("aceptar_miembro", { p_caso_id: casoId, p_user_id: userId }),
    reject: (casoId, userId) => call("rechazar_miembro", { p_caso_id: casoId, p_user_id: userId }),
    joinGroup: (casoId) => call("unirme", { p_caso_id: casoId }),
    removeMember: (casoId, userId) => call("retirar_miembro", { p_caso_id: casoId, p_user_id: userId }),
    resolve: (casoId) => call("resolver_caso", { p_caso_id: casoId }),
    cancel: (id) => call("cancelar_publicacion", { p_id: id }),
    reopen: (casoId) => call("reabrir_caso", { p_caso_id: casoId }),
    retireAnuncio: (id) => call("cancelar_publicacion", { p_id: id }),
    editAnuncio: (id, title, description) => {
      const text = parseAnnouncement(title, description);
      return call("editar_anuncio", { p_id: id, p_title: text.title, p_description: text.description });
    },
    sendMessage: (casoId, body) => call("enviar_mensaje", { p_caso_id: casoId, p_body: parseMessage(body) }),
    recommend: (anuncioId) => call("recomendar", { p_anuncio_id: anuncioId }),
    rate: (casoId, score, comment) =>
      call("valorar", {
        p_caso_id: casoId,
        p_score: parseScore(score),
        p_comment: parseComment(comment),
      }),
    report: (targetType, targetId, reason) =>
      call("reportar", { p_target_type: targetType, p_target_id: targetId, p_reason: parseReason(reason) }),
    block: (userId) => call("bloquear", { p_user_id: userId }),
    unblock: (userId) => call("desbloquear", { p_user_id: userId }),
    async blocks() {
      const rows = await call<BlockView[]>("listar_bloqueos");
      return rows ?? [];
    },
    sharePhone: (casoId, phone) =>
      call("compartir_telefono", { p_caso_id: casoId, p_phone: parsePhone(phone) }),

    async pendingPublishes() {
      return 0;
    },

    async flushPublishes() {
      return 0;
    },

    async pendingMessages() {
      return 0;
    },

    async flushMessages() {
      return 0;
    },

    subscribeMessages(casoId, onChange) {
      const channel = client
        .channel(`mensajes:${casoId}`)
        .on(
          "postgres_changes",
          {
            event: "INSERT",
            schema: "public",
            table: "mensajes",
            filter: `publicacion_id=eq.${casoId}`,
          },
          () => onChange(),
        )
        .subscribe();
      return () => {
        void client.removeChannel(channel);
      };
    },

    watchSession(onChange) {
      const { data } = client.auth.onAuthStateChange(() => onChange());
      return () => data.subscription.unsubscribe();
    },
  };

  return api;
}

async function authUser(client: SupabaseClient) {
  const { data, error } = await client.auth.getSession();
  if (error) throw fromRemoteMessage(error.message);
  return data.session?.user ?? null;
}
