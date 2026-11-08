import { useEffect, useId, useRef, useState, type FormEvent } from "react";
import type { ViewerPoint } from "../data/api";
import type { YuntaApi } from "../data";
import { asYuntaError } from "../domain/errors";
import { HELP_LABEL } from "../domain/labels";
import { HELP_TYPES, type HelpType, type Intent } from "../domain/types";

interface Props {
  api: YuntaApi;
  open: boolean;
  point: ViewerPoint | null;
  onAskPoint: () => void;
  onClose: () => void;
  onCreated: (id: string) => void;
}

const INTENTS: { id: Intent; label: string }[] = [
  { id: "pido_ayuda", label: "Pido ayuda" },
  { id: "ofrezco_ayuda", label: "Ofrezco ayuda ahora" },
  { id: "servicio", label: "Ofrezco un oficio" },
  { id: "producto", label: "Ofrezco un producto" },
  { id: "emergencia_persona", label: "Emergencia de una persona" },
  { id: "emergencia_cuadra", label: "Emergencia de una cuadra" },
  { id: "emergencia_recurso", label: "Recurso para la emergencia" },
  { id: "grupo_apoyo", label: "Grupo de apoyo" },
];

/**
 * El identificador del envío nace al abrir el formulario y no cambia
 * si la persona reintenta. Así un aviso sin señal no se duplica.
 */
export function PublishDialog({ api, open, point, onAskPoint, onClose, onCreated }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const requestId = useRef(crypto.randomUUID());
  const titleId = useId();
  const [intent, setIntent] = useState<Intent>("pido_ayuda");
  const [helpType, setHelpType] = useState<HelpType>("herramienta");
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [areaLabel, setAreaLabel] = useState("");
  const [usePoint, setUsePoint] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    requestId.current = crypto.randomUUID();
    setError(null);
    const dialog = dialogRef.current;
    if (dialog && !dialog.open) dialog.showModal();
    return () => {
      dialogRef.current?.close();
    };
  }, [open]);

  if (!open) return null;

  const needsHelp = intent === "pido_ayuda" || intent === "ofrezco_ayuda";
  const isEmergency = intent.startsWith("emergencia");

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const created = await api.publish({
        intent,
        helpType: needsHelp ? helpType : undefined,
        title,
        description,
        areaLabel: areaLabel.trim() || undefined,
        lat: usePoint ? point?.lat : undefined,
        lng: usePoint ? point?.lng : undefined,
        clientRequestId: requestId.current,
      });
      onCreated(created.id);
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
      <form className="stack" onSubmit={submit}>
        <h2 id={titleId}>Publicar</h2>
        <fieldset className="choices">
          <legend>Qué quieres publicar</legend>
          {INTENTS.map((option) => (
            <label key={option.id}>
              <input
                type="radio"
                name="intent"
                checked={intent === option.id}
                onChange={() => setIntent(option.id)}
              />
              {option.label}
            </label>
          ))}
        </fieldset>
        {needsHelp ? (
          <label>
            Tipo de favor
            <select value={helpType} onChange={(event) => setHelpType(event.target.value as HelpType)}>
              {HELP_TYPES.map((type) => (
                <option key={type} value={type}>
                  {HELP_LABEL[type]}
                </option>
              ))}
            </select>
          </label>
        ) : null}
        <label>
          Título
          <input required minLength={3} maxLength={80} value={title} onChange={(event) => setTitle(event.target.value)} />
        </label>
        <label>
          Detalle
          <textarea maxLength={500} value={description} onChange={(event) => setDescription(event.target.value)} />
        </label>
        <label>
          Referencia visible
          <input
            maxLength={40}
            placeholder="Ej. cerca del mercado"
            value={areaLabel}
            onChange={(event) => setAreaLabel(event.target.value)}
          />
        </label>
        <p className="muted">
          {isEmergency
            ? "Una persona se coordina entre dos. Una cuadra o un recurso, en grupo."
            : "Un oficio queda publicado. Cada vecino abre su propia coordinación."}
        </p>
        <label>
          <span>
            <input
              type="checkbox"
              checked={usePoint}
              onChange={(event) => {
                setUsePoint(event.target.checked);
                if (event.target.checked && !point) onAskPoint();
              }}
            />{" "}
            Marcar un punto aproximado. No se muestra la dirección.
          </span>
        </label>
        {error ? <p role="alert">{error}</p> : null}
        <div className="row">
          <button className="btn btn-primary" type="submit" disabled={busy}>
            Publicar
          </button>
          <button className="btn btn-ghost" type="button" onClick={onClose}>
            Cerrar
          </button>
        </div>
      </form>
    </dialog>
  );
}
