import { useEffect, useId, useRef, useState, type FormEvent } from "react";
import type { ViewerPoint } from "../data/api";
import type { YuntaApi } from "../data";
import { asYuntaError } from "../domain/errors";
import { DEFAULT_PUBLISH_CHOICE, PUBLISH_CHOICES, publishChoice } from "../domain/publish-choices";

interface Props {
  api: YuntaApi;
  open: boolean;
  point: ViewerPoint | null;
  onAskPoint: () => void;
  onClose: () => void;
  onCreated: (id: string) => void;
}

const GROUPS = [
  { id: "favor", legend: "Favor" },
  { id: "directorio", legend: "Oficio o producto" },
  { id: "emergencia", legend: "Emergencia" },
] as const;

/**
 * El identificador del envío nace al abrir el formulario y no cambia
 * si la persona reintenta. Así un aviso sin señal no se duplica.
 */
export function PublishDialog({ api, open, point, onAskPoint, onClose, onCreated }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleRef = useRef<HTMLInputElement>(null);
  const requestId = useRef(crypto.randomUUID());
  const titleId = useId();
  const [choiceId, setChoiceId] = useState(DEFAULT_PUBLISH_CHOICE);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [areaLabel, setAreaLabel] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    requestId.current = crypto.randomUUID();
    setChoiceId(DEFAULT_PUBLISH_CHOICE);
    setError(null);
    const dialog = dialogRef.current;
    if (dialog && !dialog.open) dialog.showModal();
    titleRef.current?.focus();
    return () => {
      dialogRef.current?.close();
    };
  }, [open]);

  if (!open) return null;

  const choice = publishChoice(choiceId);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const created = await api.publish({
        intent: choice.intent,
        helpType: choice.helpType,
        title,
        description,
        areaLabel: areaLabel.trim() || undefined,
        lat: point?.lat,
        lng: point?.lng,
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
        {GROUPS.map((group) => (
          <fieldset key={group.id} className="choices">
            <legend>{group.legend}</legend>
            {PUBLISH_CHOICES.filter((option) => option.group === group.id).map((option) => (
              <label key={option.id}>
                <input
                  type="radio"
                  name="publish-choice"
                  checked={choiceId === option.id}
                  onChange={() => {
                    setChoiceId(option.id);
                    titleRef.current?.focus();
                    if (option.intent.startsWith("emergencia") && !point) onAskPoint();
                  }}
                />
                {option.label}
              </label>
            ))}
          </fieldset>
        ))}
        <label>
          Título
          <input
            ref={titleRef}
            required
            minLength={3}
            maxLength={80}
            autoComplete="off"
            value={title}
            onChange={(event) => setTitle(event.target.value)}
          />
        </label>
        <label>
          Detalle
          <textarea
            maxLength={500}
            autoComplete="off"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
          />
        </label>
        <label>
          Referencia visible
          <input
            maxLength={40}
            autoComplete="off"
            placeholder="Ej. cerca del mercado"
            value={areaLabel}
            onChange={(event) => setAreaLabel(event.target.value)}
          />
        </label>
        <p className="muted">
          Abrir, elegir y publicar. Escribir el título no suma un toque.
          {point
            ? " Tu ubicación aproxima el aviso y la dirección no se muestra."
            : " Sin ubicación, el aviso usa el centro de tu zona."}
        </p>
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
