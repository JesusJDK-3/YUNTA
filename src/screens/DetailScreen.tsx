import { useEffect, useState, type FormEvent } from "react";
import type { YuntaApi } from "../data";
import { asYuntaError } from "../domain/errors";
import { modeLabel, statusLabel } from "../domain/labels";
import type { Detail } from "../domain/types";

interface Props {
  api: YuntaApi;
  id: string;
  userId: string;
  onBack: () => void;
  onOpen: (id: string) => void;
}

function detailStamp(detail: Detail | null): string {
  if (!detail) return "";
  const last = detail.messages.at(-1);
  return [
    detail.item.status,
    detail.item.title,
    detail.messages.length,
    last?.id ?? "",
    last?.body ?? "",
    detail.pending.length,
    detail.members.length,
    detail.chatOpen,
    detail.canSend,
  ].join("|");
}

export function DetailScreen({ api, id, userId, onBack, onOpen }: Props) {
  const [detail, setDetail] = useState<Detail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [reason, setReason] = useState("");
  const [phone, setPhone] = useState("");
  const [score, setScore] = useState(5);
  const [comment, setComment] = useState("");
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");

  useEffect(() => {
    let cancelled = false;
    let hydrated = false;

    async function load() {
      try {
        const next = await api.detail(id);
        if (cancelled) return;
        setDetail((current) => (detailStamp(current) === detailStamp(next) ? current : next));
        // El refresco del chat no pisa un título que la persona ya está editando.
        if (!hydrated) {
          hydrated = true;
          setTitle(next.item.title);
          setDescription(next.item.description);
        }
        setError(null);
      } catch (caught) {
        if (!cancelled) setError(asYuntaError(caught).message);
      }
    }

    void load();
    // Mientras el caso está abierto, se vuelve a leer si llega un mensaje
    // o cada 8 segundos con la pestaña visible. No guarda el punto.
    const unsub = api.subscribeMessages(id, () => {
      void load();
    });
    const timer = window.setInterval(() => {
      if (document.visibilityState === "visible") void load();
    }, 8000);
    return () => {
      cancelled = true;
      unsub();
      window.clearInterval(timer);
    };
  }, [api, id]);

  async function run(action: () => Promise<void>, ok?: string) {
    setBusy(true);
    setError(null);
    try {
      await action();
      setDetail(await api.detail(id));
      if (ok) setInfo(ok);
    } catch (caught) {
      setError(asYuntaError(caught).message);
    } finally {
      setBusy(false);
    }
  }

  async function send(event: FormEvent) {
    event.preventDefault();
    const body = message;
    setMessage("");
    setBusy(true);
    setError(null);
    try {
      await api.sendMessage(id, body);
      const next = await api.detail(id);
      setDetail(next);
      if (next.messages.some((entry) => entry.pending && entry.body === body)) {
        setInfo("Sin conexión. El mensaje quedó en este celular y se enviará al volver la señal.");
      }
    } catch (caught) {
      setMessage(body);
      setError(asYuntaError(caught).message);
    } finally {
      setBusy(false);
    }
  }

  if (error && !detail) {
    return (
      <main className="sheet">
        <button type="button" className="btn back" onClick={onBack}>
          Volver
        </button>
        <p role="alert">{error}</p>
      </main>
    );
  }

  if (!detail) {
    return (
      <main className="sheet">
        <p>Cargando el aviso…</p>
      </main>
    );
  }

  const item = detail.item;

  return (
    <main className="sheet">
      <button type="button" className="btn back" onClick={onBack}>
        Volver al muro
      </button>
      <h1>{item.title}</h1>
      <p className="meta">
        {detail.isAuthor && detail.myStatus === "pendiente"
          ? `Solicitud enviada · ${item.areaLabel}`
          : `${item.authorName} · ${item.areaLabel}`}
        {item.distanceLabel ? ` · ${item.distanceLabel}` : ""}
      </p>
      <p className="meta">
        {[modeLabel(item.coordinationMode), statusLabel(item.status)].filter(Boolean).join(" · ")}
      </p>
      {item.category === "emergencia" ? <p className="tag">Emergencia</p> : null}
      {detail.offline ? (
        <p className="banner" role="status">
          Sin conexión. Ves la última ficha guardada. El mensaje que escribas queda en este celular.
        </p>
      ) : null}
      <p>{item.description}</p>
      {item.kind === "anuncio" && item.recommendationCount > 0 ? (
        <p>Recomendado por {item.recommendationCount} vecinos de {item.zoneName}.</p>
      ) : null}
      {item.ratingAverage !== null ? (
        <p>Valoración {item.ratingAverage}, a partir de {item.ratingCount} atenciones.</p>
      ) : null}
      {detail.myStatus === "pendiente" ? (
        <p className="banner">Esperando que acepten. El chat se abre después.</p>
      ) : null}
      {error ? <p className="banner" data-tone="alert" role="alert">{error}</p> : null}
      {info ? <p className="banner" role="status">{info}</p> : null}

      <div className="row" style={{ margin: "0.75rem 0" }}>
        {detail.canOfferHelp ? (
          <button type="button" className="btn btn-action" disabled={busy} onClick={() => void run(() => api.requestEntry(id))}>
            Puedo ayudar
          </button>
        ) : null}
        {detail.canRequestHelp ? (
          <button type="button" className="btn btn-action" disabled={busy} onClick={() => void run(() => api.requestEntry(id))}>
            La necesito
          </button>
        ) : null}
        {detail.canJoinGroup ? (
          <button type="button" className="btn btn-action" disabled={busy} onClick={() => void run(() => api.joinGroup(id))}>
            Unirme
          </button>
        ) : null}
        {item.kind === "anuncio" && !detail.isAuthor ? (
          <button
            type="button"
            className="btn btn-primary"
            disabled={busy}
            onClick={() => void run(async () => {
              const created = await api.coordinate(id, crypto.randomUUID());
              onOpen(created.id);
            })}
          >
            Quiero coordinar
          </button>
        ) : null}
        {detail.canRecommend ? (
          <button type="button" className="btn btn-ghost" disabled={busy} onClick={() => void run(() => api.recommend(id), "Listo. Tu visto bueno quedó en el anuncio.")}>
            Recomendar
          </button>
        ) : null}
        {detail.alreadyRecommended ? <p className="muted">Ya recomendaste este anuncio.</p> : null}
        {detail.canResolve ? (
          <button type="button" className="btn btn-ghost" disabled={busy} onClick={() => void run(() => api.resolve(id))}>
            Marcar resuelto
          </button>
        ) : null}
        {detail.canReopen ? (
          <button type="button" className="btn btn-ghost" disabled={busy} onClick={() => void run(() => api.reopen(id))}>
            Reabrir
          </button>
        ) : null}
        {detail.canCancel ? (
          <button type="button" className="btn btn-danger" disabled={busy} onClick={() => void run(() => api.cancel(id))}>
            {item.kind === "anuncio" ? "Retirar anuncio" : "Cancelar"}
          </button>
        ) : null}
      </div>

      {detail.pending.length > 0 ? (
        <section>
          <h2>Solicitudes</h2>
          {detail.pending.map((person) => (
            <div key={person.userId} className="row">
              <span>{person.displayName}</span>
              <button type="button" className="btn btn-action" disabled={busy} onClick={() => void run(() => api.accept(id, person.userId))}>
                Aceptar
              </button>
              <button type="button" className="btn btn-ghost" disabled={busy} onClick={() => void run(() => api.reject(id, person.userId))}>
                Rechazar
              </button>
            </div>
          ))}
        </section>
      ) : null}

      {detail.canEdit ? (
        <form
          className="stack"
          onSubmit={(event) => {
            event.preventDefault();
            void run(() => api.editAnuncio(id, title, description), "Anuncio actualizado.");
          }}
        >
          <h2>Editar anuncio</h2>
          <label>
            Título
            <input autoComplete="off" value={title} maxLength={80} onChange={(event) => setTitle(event.target.value)} />
          </label>
          <label>
            Detalle
            <textarea value={description} maxLength={500} onChange={(event) => setDescription(event.target.value)} />
          </label>
          <button className="btn btn-ghost" type="submit" disabled={busy}>Guardar</button>
        </form>
      ) : null}

      {detail.members.length > 0 ? (
        <section>
          <h2>En este caso</h2>
          <ul>
            {detail.members.map((person) => (
              <li key={person.userId}>
                {person.displayName}
                {item.coordinationMode === "grupal" && detail.isAuthor && person.userId !== item.authorId ? (
                  <button type="button" className="btn btn-ghost" disabled={busy} onClick={() => void run(() => api.removeMember(id, person.userId))}>
                    Sacar
                  </button>
                ) : null}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {detail.chatOpen ? (
        <section>
          <h2>Chat del caso</h2>
          <div className="chat" aria-live="polite">
            {detail.messages.length === 0 ? <p className="muted">Todavía no hay mensajes.</p> : null}
            {detail.messages.map((entry) => (
              <p key={entry.id} className={entry.pending || entry.senderId === userId ? "bubble mine" : "bubble"}>
                <strong>{entry.senderName}. </strong>
                {entry.body}
                {entry.pending ? <span className="meta"> Pendiente de envío.</span> : null}
              </p>
            ))}
          </div>
          {detail.canSend ? (
            <form className="stack" onSubmit={send}>
              <label>
                Mensaje
                <input autoComplete="off" maxLength={500} value={message} onChange={(event) => setMessage(event.target.value)} />
              </label>
              <button className="btn btn-action" type="submit" disabled={busy || !message.trim()}>
                Enviar
              </button>
            </form>
          ) : (
            <p className="muted">El chat queda para consulta.</p>
          )}
          {detail.canSharePhone ? (
            <form
              className="stack"
              onSubmit={(event) => {
                event.preventDefault();
                void run(() => api.sharePhone(id, phone), "Número compartido solo en este chat.");
              }}
            >
              <label>
                Compartir mi número
                <input
                  inputMode="tel"
                  autoComplete="tel"
                  maxLength={16}
                  value={phone}
                  onChange={(event) => setPhone(event.target.value)}
                  placeholder="+51987654321"
                />
              </label>
              <button className="btn btn-ghost" type="submit" disabled={busy}>Enviar número a este chat</button>
            </form>
          ) : null}
        </section>
      ) : null}

      {detail.canRate ? (
        <form
          className="stack"
          onSubmit={(event) => {
            event.preventDefault();
            void run(() => api.rate(id, score, comment), "Gracias. La nota se publica desde la tercera valoración.");
          }}
        >
          <h2>Valorar a quien ayudó</h2>
          <label>
            Nota de 1 a 5
            <input
              type="number"
              min={1}
              max={5}
              value={score}
              onChange={(event) => setScore(Number(event.target.value))}
            />
          </label>
          <label>
            Comentario, si quieres
            <textarea maxLength={280} value={comment} onChange={(event) => setComment(event.target.value)} />
          </label>
          <button className="btn btn-primary" type="submit" disabled={busy}>Valorar</button>
        </form>
      ) : null}
      {detail.myRating ? <p>Tu valoración: {detail.myRating.score}.</p> : null}

      {!detail.isAuthor ? (
        <form
          className="stack"
          onSubmit={(event) => {
            event.preventDefault();
            void run(() => api.report("publicacion", id, reason), "Reporte registrado. Quien publicó no ve tu nombre.");
          }}
        >
          <h2>Reportar</h2>
          <label>
            Qué pasó
            <input autoComplete="off" maxLength={200} value={reason} onChange={(event) => setReason(event.target.value)} />
          </label>
          <div className="row">
            <button className="btn btn-danger" type="submit" disabled={busy}>Reportar</button>
            <button
              type="button"
              className="btn btn-ghost"
              disabled={busy}
              onClick={() => void run(() => api.block(item.authorId), "Bloqueado. Ya no verás sus avisos.")}
            >
              Bloquear
            </button>
          </div>
        </form>
      ) : null}
    </main>
  );
}
