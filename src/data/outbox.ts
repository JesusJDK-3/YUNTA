/**
 * Bandeja de publicación.
 * Si el servidor no responde, el aviso se queda en el celular con el mismo
 * identificador. Al reintentar, la base reconoce ese id y no crea un duplicado.
 * Un error de validación no se reintenta: no va a volverse válido solo.
 */

import { asYuntaError } from "../domain/errors";
import type { YuntaApi } from "./api";

const OUTBOX_KEY = "yunta.outbox.v1";

interface PendingPublish {
  input: unknown;
  savedAt: string;
}

export function withOutbox(inner: YuntaApi, storage: Storage): YuntaApi {
  function read(): PendingPublish[] {
    try {
      const parsed = JSON.parse(storage.getItem(OUTBOX_KEY) ?? "[]") as PendingPublish[];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  function write(items: PendingPublish[]): void {
    storage.setItem(OUTBOX_KEY, JSON.stringify(items));
  }

  return {
    ...inner,
    async signOut() {
      storage.removeItem(OUTBOX_KEY);
      await inner.signOut();
    },
    async publish(input: unknown) {
      try {
        return await inner.publish(input);
      } catch (error) {
        const yunta = asYuntaError(error);
        if (yunta.code !== "network") throw yunta;
        const items = read();
        items.push({ input, savedAt: new Date().toISOString() });
        write(items);
        throw yunta;
      }
    },
    async pendingPublishes() {
      return read().length;
    },
    async flushPublishes() {
      const items = read();
      const left: PendingPublish[] = [];
      let sent = 0;
      for (const item of items) {
        try {
          await inner.publish(item.input);
          sent += 1;
        } catch (error) {
          const yunta = asYuntaError(error);
          if (yunta.code === "network") left.push(item);
          // validation, forbidden, conflict: se descarta. Reintentarlo no lo arregla.
        }
      }
      write(left);
      return sent;
    },
  };
}
