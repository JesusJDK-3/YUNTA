import { useEffect, useMemo, useState } from "react";
import { PublishDialog } from "../components/PublishDialog";
import { Wordmark } from "../components/Wordmark";
import type { YuntaApi } from "../data";
import { asYuntaError } from "../domain/errors";
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
}

const TABS: { id: FeedTab; label: string }[] = [
  { id: "ayuda", label: "Ayuda" },
  { id: "servicios", label: "Productos y servicios" },
  { id: "emergencias", label: "Emergencias" },
];

export function WallScreen({ api, session, notice, clearNotice, place, onOpen, onLeave }: Props) {
  const [tab, setTab] = useState<FeedTab>("ayuda");
  const [items, setItems] = useState<FeedItem[]>([]);
  const [needsLocation, setNeedsLocation] = useState(false);
  const [query, setQuery] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [publishing, setPublishing] = useState(false);
  const [pending, setPending] = useState(0);
  const [blocks, setBlocks] = useState<BlockView[]>([]);
  const [zoneId, setZoneId] = useState(session.zoneId);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    void api
      .feed(tab, place.point)
      .then((result) => {
        if (cancelled) return;
        setItems(result.items);
        setNeedsLocation(result.needsLocation);
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
    void Promise.all([api.pendingPublishes(), api.blocks()]).then(([count, rows]) => {
      if (cancelled) return;
      setPending(count);
      setBlocks(rows);
    });
    return () => {
      cancelled = true;
    };
  }, [api, items]);

  // El servidor ya entregó como máximo 40. Filtrar aquí no vuelve a pedir la red.
  const shown = useMemo(() => {
    const needle = query.trim().toLowerCase();
    if (!needle) return items;
    return items.filter((item) =>
      `${item.title} ${item.description} ${item.authorName}`.toLowerCase().includes(needle),
    );
  }, [items, query]);

  async function saveZone() {
    try {
      await api.saveProfile(session.displayName, zoneId);
      window.location.assign("/muro");
    } catch (caught) {
      setError(asYuntaError(caught).message);
    }
  }

  return (
    <main className="sheet">
      <header className="top">
        <div className="grow">
          <Wordmark compact />
          <p className="meta">Cerca de ti · {session.zoneName}</p>
        </div>
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
          {pending} aviso{pending === 1 ? "" : "s"} pendiente{pending === 1 ? "" : "s"} de envío.
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
      {!loading && shown.length === 0 ? (
        <p>No hay avisos con ese filtro. Puedes publicar el primero.</p>
      ) : null}

      <div className="stack" style={{ marginTop: "0.75rem" }}>
        {shown.map((item) => (
          <button key={item.id} type="button" className="card" onClick={() => onOpen(item.id)}>
            <strong>{item.title}</strong>
            <p className="meta">
              {item.authorName} · {item.areaLabel}
              {item.distanceLabel ? ` · ${item.distanceLabel}` : ""}
            </p>
            <p className="meta">
              {[modeLabel(item.coordinationMode), statusLabel(item.status)].filter(Boolean).join(" · ")}
              {item.recommendationCount > 0
                ? ` · Recomendado por ${item.recommendationCount} vecinos`
                : ""}
              {item.ratingAverage !== null ? ` · Valoración ${item.ratingAverage}` : ""}
            </p>
            {item.category === "emergencia" ? <span className="tag">Emergencia</span> : null}
          </button>
        ))}
      </div>

      <details style={{ marginTop: "1.5rem" }}>
        <summary>Tu zona y bloqueos</summary>
        <div className="stack" style={{ marginTop: "0.75rem" }}>
          <label>
            Zona activa
            <select value={zoneId} onChange={(event) => setZoneId(event.target.value as Session["zoneId"])}>
              <option value="norte">Zona Norte</option>
              <option value="centro">Zona Centro</option>
              <option value="sur">Zona Sur</option>
              <option value="este">Zona Este</option>
            </select>
          </label>
          <button type="button" className="btn btn-ghost" onClick={() => void saveZone()}>
            Guardar zona
          </button>
          {blocks.length === 0 ? <p className="muted">No has bloqueado a nadie.</p> : null}
          {blocks.map((block) => (
            <button
              key={block.userId}
              type="button"
              className="btn btn-ghost"
              onClick={() => void api.unblock(block.userId).then(() => setBlocks((rows) => rows.filter((row) => row.userId !== block.userId)))}
            >
              Desbloquear a {block.displayName}
            </button>
          ))}
        </div>
      </details>

      <button type="button" className="btn btn-primary fab" onClick={() => setPublishing(true)}>
        Publicar
      </button>
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
