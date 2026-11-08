import { useEffect, useMemo, useRef, useState } from "react";
import { AccountDialog } from "../components/AccountDialog";
import { PublishDialog } from "../components/PublishDialog";
import { Wordmark } from "../components/Wordmark";
import type { YuntaApi } from "../data";
import { splitEmergencyBoard } from "../domain/boards";
import { asYuntaError } from "../domain/errors";
import { parseSearch } from "../domain/rules";
import { modeLabel, statusLabel } from "../domain/labels";
import type { BlockView, FeedItem, FeedTab, Session } from "../domain/types";
import type { usePlace } from "../lib/place";

interface Props {
  api: YuntaApi;
  session: Session;
  notice: string | null;
  clearNotice: () => void;
  place: ReturnType<typeof usePlace>;
  onOpen: (id: string) => void;
  onLeave: () => void;
  onProfile: (session: Session) => void;
}

const TABS: { id: FeedTab; label: string }[] = [
  { id: "ayuda", label: "Ayuda" },
  { id: "servicios", label: "Productos y servicios" },
  { id: "emergencias", label: "Emergencias" },
];

export function WallScreen({ api, session, notice, clearNotice, place, onOpen, onLeave, onProfile }: Props) {
  const [tab, setTab] = useState<FeedTab>("ayuda");
  const [items, setItems] = useState<FeedItem[]>([]);
  const [needsLocation, setNeedsLocation] = useState(false);
  const [query, setQuery] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [publishing, setPublishing] = useState(false);
  const [accountOpen, setAccountOpen] = useState(false);
  const [pending, setPending] = useState(0);
  const [offline, setOffline] = useState(false);
  const [blocks, setBlocks] = useState<BlockView[]>([]);
  const feedCache = useRef(new Map<string, { items: FeedItem[]; needsLocation: boolean; offline: boolean }>());

  useEffect(() => {
    let cancelled = false;
    const key = `${tab}|${session.zoneId}|${place.point?.lat ?? ""}|${place.point?.lng ?? ""}`;
    const cached = feedCache.current.get(key);
    // Si ya vimos esta lista, se pinta al instante y el pedido nuevo no borra la pantalla.
    if (cached) {
      setItems(cached.items);
      setNeedsLocation(cached.needsLocation);
      setOffline(cached.offline);
      setLoading(false);
    } else {
      setLoading(true);
    }
    void api
      .feed(tab, place.point)
      .then((result) => {
        if (cancelled) return;
        const offline = Boolean(result.offline);
        feedCache.current.set(key, { items: result.items, needsLocation: result.needsLocation, offline });
        setItems((current) => (sameFeed(current, result.items) ? current : result.items));
        setNeedsLocation(result.needsLocation);
        setOffline(offline);
        setError(null);
      })
      .catch((caught: unknown) => {
        if (!cancelled) setError(asYuntaError(caught).message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [api, tab, place.point, session.zoneId]);

  useEffect(() => {
    if (tab === "emergencias" && place.status === "idle") place.ask();
  }, [tab, place.status, place.ask]);

  useEffect(() => {
    let cancelled = false;
    void Promise.all([api.pendingPublishes(), api.pendingMessages(), api.blocks()]).then(([posts, messages, rows]) => {
      if (cancelled) return;
      setPending(posts + messages);
      setBlocks(rows);
    });
    return () => {
      cancelled = true;
    };
  }, [api, items]);

  // El servidor ya entregó como máximo 40. Filtrar aquí no vuelve a pedir la red.
  const shown = useMemo(() => {
    const needle = parseSearch(query);
    if (!needle) return items;
    return items.filter((item) =>
      `${item.title} ${item.description} ${item.authorName}`.toLowerCase().includes(needle),
    );
  }, [items, query]);
  const boards = useMemo(() => splitEmergencyBoard(shown), [shown]);

  const initial = session.displayName.trim().charAt(0).toUpperCase() || "Y";

  return (
    <main className="sheet">
      <header className="top">
        <div className="grow">
          <Wordmark compact />
          <p className="meta">Cerca de ti · {session.zoneName}</p>
        </div>
        <button
          type="button"
          className="user-button"
          aria-label={`Mis datos, ${session.displayName}`}
          onClick={() => setAccountOpen(true)}
        >
          {initial}
        </button>
        <button type="button" className="btn btn-ghost" onClick={onLeave}>
          Salir
        </button>
      </header>
      {notice ? (
        <p className="banner" role="status">
          {notice}{" "}
          <button type="button" className="btn btn-ghost" onClick={clearNotice}>
            Ocultar
          </button>
        </p>
      ) : null}
      {pending > 0 ? (
        <p className="banner" role="status">
          {pending === 1 ? "1 pendiente de envío." : `${pending} pendientes de envío.`}
        </p>
      ) : null}
      {offline ? (
        <p className="banner" role="status">
          Sin conexión. Esta es la última lista guardada. La búsqueda funciona sobre ella.
        </p>
      ) : null}
      {error ? <p className="banner" data-tone="alert" role="alert">{error}</p> : null}

      <div className="tabs" role="tablist" aria-label="Secciones del muro">
        {TABS.map((item) => (
          <button
            key={item.id}
            type="button"
            className="tab"
            role="tab"
            aria-selected={tab === item.id}
            onClick={() => setTab(item.id)}
          >
            {item.label}
          </button>
        ))}
      </div>

      <label>
        Buscar en esta lista
        <input
          type="search"
          maxLength={80}
          autoComplete="off"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Gasfiter, muleta, baldes"
        />
      </label>

      {needsLocation ? (
        <p className="banner">
          Sin ubicación solo ves los grupos de apoyo de tu zona.{" "}
          <button type="button" className="btn btn-action" onClick={place.ask} disabled={place.status === "loading"}>
            Usar mi ubicación
          </button>
        </p>
      ) : null}

      {loading ? <p>Cargando el muro…</p> : null}
      {!loading && tab !== "emergencias" && shown.length === 0 ? (
        <p>No hay avisos con ese filtro. Puedes publicar el primero.</p>
      ) : null}

      {tab === "emergencias" && !loading ? (
        <>
          <Board
            title="Tablero de ayuda humanitaria"
            hint="Vecinos y cuadras que piden apoyo cerca de ti."
            empty={needsLocation ? "Con la ubicación aparecen los reportes a 500 m." : "Todavía no hay reportes cerca."}
            items={boards.humanitario}
            onOpen={onOpen}
          />
          <Board
            title="Economía solidaria"
            hint="Espacio para coordinar y compartir recursos críticos, sin dinero."
            empty={needsLocation ? "Con la ubicación aparecen los recursos a 500 m." : "Todavía no hay recursos críticos."}
            items={boards.solidaria}
            onOpen={onOpen}
          />
          <Board
            title="Grupos de apoyo"
            hint="Servicios y grupos disponibles en tu zona durante la emergencia."
            empty="Todavía no hay grupos de apoyo en tu zona."
            items={boards.apoyo}
            onOpen={onOpen}
          />
        </>
      ) : (
        <div className="stack" style={{ marginTop: "0.75rem" }}>
          {shown.map((item) => (
            <FeedCard key={item.id} item={item} onOpen={onOpen} />
          ))}
        </div>
      )}

      <button type="button" className="btn btn-primary fab" onClick={() => setPublishing(true)}>
        Publicar
      </button>
      <AccountDialog
        open={accountOpen}
        api={api}
        session={session}
        place={place}
        blocks={blocks}
        onUnblock={(userId) => {
          void api.unblock(userId).then(() => setBlocks((rows) => rows.filter((row) => row.userId !== userId)));
        }}
        onClose={() => setAccountOpen(false)}
        onSaved={onProfile}
      />
      <PublishDialog
        api={api}
        open={publishing}
        point={place.point}
        onAskPoint={place.ask}
        onClose={() => setPublishing(false)}
        onCreated={(id) => {
          setPublishing(false);
          onOpen(id);
        }}
      />
    </main>
  );
}

function FeedCard({ item, onOpen }: { item: FeedItem; onOpen: (id: string) => void }) {
  return (
    <button type="button" className="card" onClick={() => onOpen(item.id)}>
      <strong>{item.title}</strong>
      <p className="meta">
        {item.authorName} · {item.areaLabel}
        {item.distanceLabel ? ` · ${item.distanceLabel}` : ""}
      </p>
      <p className="meta">
        {[modeLabel(item.coordinationMode), statusLabel(item.status)].filter(Boolean).join(" · ")}
        {item.recommendationCount > 0 ? ` · Recomendado por ${item.recommendationCount} vecinos` : ""}
        {item.ratingAverage !== null ? ` · Valoración ${item.ratingAverage}` : ""}
      </p>
      {item.category === "emergencia" ? <span className="tag">Emergencia</span> : null}
    </button>
  );
}

function sameFeed(current: FeedItem[], next: FeedItem[]): boolean {
  if (current.length !== next.length) return false;
  return current.every((item, index) => {
    const other = next[index];
    return (
      item.id === other.id &&
      item.title === other.title &&
      item.status === other.status &&
      item.recommendationCount === other.recommendationCount &&
      item.ratingAverage === other.ratingAverage
    );
  });
}

function Board({
  title,
  hint,
  empty,
  items,
  onOpen,
}: {
  title: string;
  hint: string;
  empty: string;
  items: FeedItem[];
  onOpen: (id: string) => void;
}) {
  return (
    <section className="board" aria-label={title}>
      <h2>{title}</h2>
      <p className="muted">{hint}</p>
      {items.length === 0 ? <p>{empty}</p> : null}
      <div className="stack">
        {items.map((item) => (
          <FeedCard key={item.id} item={item} onOpen={onOpen} />
        ))}
      </div>
    </section>
  );
}
