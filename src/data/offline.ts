/**
 * Copia local para cuando se corta la red.
 * El muro y la ficha se vuelven a leer de aquí.
 * El mensaje se guarda con su propio id y sale al volver la señal, sin duplicarse
 * en la cola: el servidor lo crea una sola vez por envío.
 */

import { YuntaError, asYuntaError } from "../domain/errors";
import type { Detail, FeedResult, FeedTab, MessageView, Session } from "../domain/types";
import type { YuntaApi } from "./api";
import { parseDetail, parseFeed, parseSession } from "./parse";

const KEY = "yunta.offline.v1";
const DETAIL_LIMIT = 30;

interface PendingMessage {
  casoId: string;
  body: string;
  localId: string;
  savedAt: string;
}

interface Snapshot {
  feeds: Partial<Record<FeedTab, FeedResult>>;
  details: { id: string; detail: Detail; savedAt: string }[];
  messages: PendingMessage[];
  session: Session | null;
}

function emptySnapshot(): Snapshot {
  return { feeds: {}, details: [], messages: [], session: null };
}

function readSnapshot(storage: Storage): Snapshot {
  try {
    const parsed = JSON.parse(storage.getItem(KEY) ?? "") as Partial<Snapshot>;
    if (!parsed || typeof parsed !== "object") return emptySnapshot();
    return {
      feeds: parsed.feeds ?? {},
      details: Array.isArray(parsed.details) ? parsed.details : [],
      messages: Array.isArray(parsed.messages) ? parsed.messages : [],
      session: parsed.session ?? null,
    };
  } catch {
    return emptySnapshot();
  }
}

function writeSnapshot(storage: Storage, snapshot: Snapshot): void {
  storage.setItem(KEY, JSON.stringify(snapshot));
}

function isNetwork(error: unknown): boolean {
  return asYuntaError(error).code === "network";
}

function cachedFeed(storage: Storage, tab: FeedTab): FeedResult | null {
  const raw = readSnapshot(storage).feeds[tab];
  if (!raw) return null;
  try {
    return parseFeed(raw);
  } catch {
    return null;
  }
}

function cachedDetail(storage: Storage, id: string): Detail | null {
  const row = readSnapshot(storage).details.find((item) => item.id === id);
  if (!row) return null;
  try {
    return parseDetail(row.detail);
  } catch {
    return null;
  }
}

function cachedSession(storage: Storage): Session | null {
  const raw = readSnapshot(storage).session;
  if (!raw) return null;
  try {
    return parseSession(raw);
  } catch {
    return null;
  }
}

function rememberFeed(storage: Storage, tab: FeedTab, result: FeedResult): void {
  const snapshot = readSnapshot(storage);
  snapshot.feeds[tab] = { items: result.items, needsLocation: result.needsLocation };
  writeSnapshot(storage, snapshot);
}

function rememberDetail(storage: Storage, detail: Detail): void {
  const snapshot = readSnapshot(storage);
  const rest = snapshot.details.filter((item) => item.id !== detail.item.id);
  rest.push({ id: detail.item.id, detail, savedAt: new Date().toISOString() });
  snapshot.details = rest.slice(-DETAIL_LIMIT);
  writeSnapshot(storage, snapshot);
}

function rememberSession(storage: Storage, session: Session | null): void {
  const snapshot = readSnapshot(storage);
  snapshot.session = session;
  writeSnapshot(storage, snapshot);
}

function queueMessage(storage: Storage, casoId: string, body: string): void {
  const snapshot = readSnapshot(storage);
  snapshot.messages.push({
    casoId,
    body,
    localId: crypto.randomUUID(),
    savedAt: new Date().toISOString(),
  });
  writeSnapshot(storage, snapshot);
}

function pendingFor(storage: Storage, casoId: string): MessageView[] {
  return readSnapshot(storage)
    .messages.filter((item) => item.casoId === casoId)
    .map((item) => ({
      id: item.localId,
      senderId: "00000000-0000-0000-0000-000000000000",
      senderName: "Tú",
      body: item.body,
      createdAt: item.savedAt,
      pending: true,
    }));
}

function withPending(detail: Detail, storage: Storage, offline: boolean): Detail {
  return {
    ...detail,
    offline,
    messages: [...detail.messages.filter((item) => !item.pending), ...pendingFor(storage, detail.item.id)],
  };
}

export function sentNotice(posts: number, messages: number): string | null {
  const bits: string[] = [];
  if (posts === 1) bits.push("1 aviso");
  else if (posts > 1) bits.push(`${posts} avisos`);
  if (messages === 1) bits.push("1 mensaje");
  else if (messages > 1) bits.push(`${messages} mensajes`);
  if (bits.length === 0) return null;
  const verb = posts + messages === 1 ? "Se envió" : "Se enviaron";
  const tail = posts + messages === 1 ? "que estaba pendiente" : "que estaban pendientes";
  return `${verb} ${bits.join(" y ")} ${tail}.`;
}

export function withOffline(inner: YuntaApi, storage: Storage): YuntaApi {
  return {
    ...inner,

    async currentSession() {
      try {
        const session = await inner.currentSession();
        rememberSession(storage, session);
        return session;
      } catch (error) {
        if (!isNetwork(error)) throw asYuntaError(error);
        const session = cachedSession(storage);
        if (session) return session;
        throw new YuntaError("network", "Sin conexión. Cuando vuelva la señal podrás entrar.");
      }
    },

    async pendingEmail() {
      try {
        return await inner.pendingEmail();
      } catch (error) {
        if (!isNetwork(error)) throw asYuntaError(error);
        if (cachedSession(storage)) return null;
        throw new YuntaError("network", "Sin conexión. Cuando vuelva la señal podrás entrar con el enlace del correo.");
      }
    },

    async signOut() {
      storage.removeItem(KEY);
      await inner.signOut();
    },

    async feed(tab, point) {
      try {
        const result = await inner.feed(tab, point);
        const fresh = { ...result, offline: false };
        rememberFeed(storage, tab, fresh);
        return fresh;
      } catch (error) {
        if (!isNetwork(error)) throw asYuntaError(error);
        const cached = cachedFeed(storage, tab);
        if (!cached) {
          throw new YuntaError("network", "Sin conexión y todavía no hay una lista guardada en este celular.");
        }
        return { ...cached, offline: true };
      }
    },

    async detail(id) {
      try {
        const detail = await inner.detail(id);
        rememberDetail(storage, detail);
        return withPending(detail, storage, false);
      } catch (error) {
        if (!isNetwork(error)) throw asYuntaError(error);
        const cached = cachedDetail(storage, id);
        if (!cached) {
          throw new YuntaError("network", "Sin conexión y este aviso no está guardado en el celular.");
        }
        return withPending(cached, storage, true);
      }
    },

    async sendMessage(casoId, body) {
      try {
        await inner.sendMessage(casoId, body);
      } catch (error) {
        if (!isNetwork(error)) throw asYuntaError(error);
        queueMessage(storage, casoId, body);
      }
    },

    async blocks() {
      try {
        return await inner.blocks();
      } catch (error) {
        if (!isNetwork(error)) throw asYuntaError(error);
        return [];
      }
    },

    async pendingMessages() {
      return readSnapshot(storage).messages.length;
    },

    async flushMessages() {
      const pending = readSnapshot(storage).messages;
      const failed = new Set<string>();
      let sent = 0;
      for (const item of pending) {
        try {
          await inner.sendMessage(item.casoId, item.body);
          sent += 1;
        } catch (error) {
          if (isNetwork(error)) failed.add(item.localId);
        }
      }
      const next = readSnapshot(storage);
      next.messages = next.messages.filter((item) => {
        const wasPending = pending.some((row) => row.localId === item.localId);
        if (!wasPending) return true;
        return failed.has(item.localId);
      });
      writeSnapshot(storage, next);
      return sent;
    },
  };
}
