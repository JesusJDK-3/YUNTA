import { useEffect, useId, useRef, useState, type FormEvent } from "react";
import type { YuntaApi } from "../data";
import { asYuntaError } from "../domain/errors";
import { nearestZone } from "../domain/rules";
import { ZONES, type BlockView, type Session } from "../domain/types";
import type { usePlace } from "../lib/place";

interface Props {
  open: boolean;
  api: YuntaApi;
  session: Session;
  place: ReturnType<typeof usePlace>;
  blocks: BlockView[];
  onUnblock: (userId: string) => void;
  onClose: () => void;
  onSaved: (session: Session) => void;
}

/**
 * Nombre y zona son los datos con los que el barrio te ve.
 * El GPS solo propone una zona. El punto no se escribe en el perfil.
 */
export function AccountDialog({ open, api, session, place, blocks, onUnblock, onClose, onSaved }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  const [name, setName] = useState(session.displayName);
  const [zoneId, setZoneId] = useState(session.zoneId);
  const [waitingPoint, setWaitingPoint] = useState(false);
  const [hint, setHint] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    setName(session.displayName);
    setZoneId(session.zoneId);
    setHint(null);
    setError(null);
    const dialog = dialogRef.current;
    if (dialog && !dialog.open) dialog.showModal();
    return () => {
      dialogRef.current?.close();
    };
  }, [open, session.displayName, session.zoneId]);

  useEffect(() => {
    if (!waitingPoint || place.status === "loading") return;
    if (place.point) {
      setZoneId(nearestZone(place.point.lat, place.point.lng));
      setHint("Sugerimos esta zona. Confírmala antes de guardar. El punto no se guarda.");
      setError(null);
    } else if (place.status === "denied") {
      setError("No se pudo usar la ubicación. Elige la zona en la lista.");
    }
    setWaitingPoint(false);
  }, [waitingPoint, place.status, place.point]);

  if (!open) return null;

  async function save(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      onSaved(await api.saveProfile(name, zoneId));
      onClose();
    } catch (caught) {
      setError(asYuntaError(caught).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <dialog
      ref={dialogRef}
      aria-labelledby={titleId}
      onClose={onClose}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
    >
      <form className="stack" onSubmit={save}>
        <h2 id={titleId}>Mis datos</h2>
        <label>
          Nombre para mostrar
          <input
            required
            minLength={2}
            maxLength={40}
            autoComplete="name"
            value={name}
            onChange={(event) => setName(event.target.value)}
          />
        </label>
        <label>
          Zona
          <select value={zoneId} onChange={(event) => setZoneId(event.target.value as Session["zoneId"])}>
            {ZONES.map((zone) => (
              <option key={zone.id} value={zone.id}>
                {zone.name}
              </option>
            ))}
          </select>
        </label>
        <button
          type="button"
          className="btn btn-ghost"
          disabled={busy || place.status === "loading"}
          onClick={() => {
            setWaitingPoint(true);
            place.ask();
          }}
        >
          {place.status === "loading" ? "Buscando ubicación…" : "Sugerir zona con mi ubicación"}
        </button>
        {hint ? <p className="muted">{hint}</p> : null}
        {error ? <p className="banner" data-tone="alert" role="alert">{error}</p> : null}
        <div className="row">
          <button className="btn btn-primary" type="submit" disabled={busy}>
            Guardar
          </button>
          <button className="btn btn-ghost" type="button" onClick={onClose}>
            Cerrar
          </button>
        </div>
      </form>
      <section className="stack" style={{ marginTop: "1rem" }}>
        <h2>Bloqueos</h2>
        {blocks.length === 0 ? <p className="muted">No has bloqueado a nadie.</p> : null}
        {blocks.map((block) => (
          <button key={block.userId} type="button" className="btn btn-ghost" onClick={() => onUnblock(block.userId)}>
            Desbloquear a {block.displayName}
          </button>
        ))}
      </section>
    </dialog>
  );
}
