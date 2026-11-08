import { describe, expect, it } from "vitest";
import { YuntaError } from "../domain/errors";
import type { Detail, FeedResult, Session } from "../domain/types";
import type { YuntaApi } from "./api";
import { sentNotice, withOffline } from "./offline";

const session: Session = {
  userId: "11111111-1111-4111-8111-111111111111",
  displayName: "Ana",
  zoneId: "centro",
  zoneName: "Zona Centro",
};

const feed: FeedResult = {
  needsLocation: false,
  items: [
    {
      id: "22222222-2222-4222-8222-222222222222",
      kind: "caso",
      category: "ayuda",
      type: "herramienta",
      title: "Muleta",
      description: "Para una semana",
      zoneId: "centro",
      zoneName: "Zona Centro",
      areaLabel: "Zona Centro",
      distanceLabel: null,
      coordinationMode: "individual",
      status: "abierto",
      recommendationCount: 0,
      ratingAverage: null,
      ratingCount: 0,
      authorId: session.userId,
      authorName: "Ana",
      sourceAnuncioId: null,
      createdAt: "2026-11-08T00:00:00.000Z",
    },
  ],
};

function detail(): Detail {
  return {
    item: feed.items[0],
    members: [],
    pending: [],
    messages: [],
    myRole: "receptor",
    myStatus: "aceptado",
    isAuthor: true,
    chatOpen: true,
    canSend: true,
    canRecommend: false,
    alreadyRecommended: false,
    canOfferHelp: false,
    canRequestHelp: false,
    canJoinGroup: false,
    canResolve: false,
    canCancel: false,
    canReopen: false,
    canSharePhone: false,
    canEdit: false,
    canRetire: false,
    canRate: false,
    myRating: null,
  };
}

function memory(): Storage {
  const map = new Map<string, string>();
  return {
    get length() {
      return map.size;
    },
    clear: () => map.clear(),
    getItem: (key) => (map.has(key) ? map.get(key)! : null),
    key: (index) => [...map.keys()][index] ?? null,
    removeItem: (key) => {
      map.delete(key);
    },
    setItem: (key, value) => {
      map.set(key, value);
    },
  };
}

describe("withOffline", () => {
  it("relee el muro, la ficha y deja el mensaje en cola cuando no hay red", async () => {
    let online = true;
    const sent: string[] = [];
    const inner = {
      async currentSession() {
        if (!online) throw new YuntaError("network");
        return session;
      },
      async feed() {
        if (!online) throw new YuntaError("network");
        return feed;
      },
      async detail() {
        if (!online) throw new YuntaError("network");
        return detail();
      },
      async sendMessage(_id: string, body: string) {
        if (!online) throw new YuntaError("network");
        sent.push(body);
      },
      async signOut() {
        online = false;
      },
    } as unknown as YuntaApi;

    const api = withOffline(inner, memory());
    expect(await api.currentSession()).toEqual(session);
    expect((await api.feed("ayuda", null)).offline).toBe(false);
    expect((await api.detail(feed.items[0].id)).offline).toBe(false);

    online = false;
    const cached = await api.feed("ayuda", null);
    expect(cached.offline).toBe(true);
    expect(cached.items[0]?.title).toBe("Muleta");
    expect(await api.currentSession()).toEqual(session);

    await api.sendMessage(feed.items[0].id, "Sigo aquí");
    const fichas = await api.detail(feed.items[0].id);
    expect(fichas.offline).toBe(true);
    expect(fichas.messages.map((row) => row.body)).toEqual(["Sigo aquí"]);
    expect(fichas.messages[0]?.pending).toBe(true);
    expect(await api.pendingMessages()).toBe(1);
    await expect(api.feed("emergencias", null)).rejects.toMatchObject({ code: "network" });

    online = true;
    expect(await api.flushMessages()).toBe(1);
    expect(sent).toEqual(["Sigo aquí"]);
    expect(await api.pendingMessages()).toBe(0);
  });

  it("no encola un mensaje que la validación rechazó", async () => {
    const inner = {
      async sendMessage() {
        throw new YuntaError("validation");
      },
      async detail() {
        return detail();
      },
    } as unknown as YuntaApi;
    const api = withOffline(inner, memory());
    await expect(api.sendMessage(feed.items[0].id, " ")).rejects.toMatchObject({ code: "validation" });
    expect(await api.pendingMessages()).toBe(0);
  });
});

describe("sentNotice", () => {
  it("nombra aviso y mensaje por separado", () => {
    expect(sentNotice(0, 0)).toBeNull();
    expect(sentNotice(1, 0)).toBe("Se envió 1 aviso que estaba pendiente.");
    expect(sentNotice(2, 1)).toBe("Se enviaron 2 avisos y 1 mensaje que estaban pendientes.");
  });
});
