import { useEffect, useState, type FormEvent } from "react";
import { Wordmark } from "../components/Wordmark";
import type { YuntaApi } from "../data";
import { asYuntaError } from "../domain/errors";
import { ZONES, type Session } from "../domain/types";

interface Props {
  api: YuntaApi;
  pendingEmail: string | null;
  notice: string | null;
  onReady: (session: Session) => void;
}

export function EnterScreen({ api, pendingEmail, notice, onReady }: Props) {
  const [name, setName] = useState("");
  const [zones, setZones] = useState<{ id: string; name: string }[]>([...ZONES]);
  const [zoneId, setZoneId] = useState<string>(ZONES[0].id);
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void api.listZones().then((rows) => {
      if (cancelled || rows.length === 0) return;
      setZones(rows);
      setZoneId((current) => (rows.some((zone) => zone.id === current) ? current : rows[0].id));
    });
    return () => {
      cancelled = true;
    };
  }, [api]);

  async function submitProfile(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      onReady(await api.saveProfile(name, zoneId));
    } catch (caught) {
      setError(asYuntaError(caught).message);
    } finally {
      setBusy(false);
    }
  }

  async function sendLink(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.requestMagicLink(email);
      setSent(true);
    } catch (caught) {
      setError(asYuntaError(caught).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="sheet">
      <Wordmark />
      <h1>Hola, vecino</h1>
      <p>Oficios, favores y emergencias de tu zona. La casa no se publica.</p>
      {notice ? <p className="banner" role="status">{notice}</p> : null}
      {error ? <p className="banner" data-tone="alert" role="alert">{error}</p> : null}

      {pendingEmail ? (
        <form className="stack" onSubmit={submitProfile}>
          <p>Entras como {pendingEmail}. Elige cómo te verán.</p>
          <label>
            Nombre para mostrar
            <input
              required
              minLength={2}
              maxLength={40}
              value={name}
              onChange={(event) => setName(event.target.value)}
            />
          </label>
          <label>
            Zona
            <select value={zoneId} onChange={(event) => setZoneId(event.target.value)}>
              {zones.map((zone) => (
                <option key={zone.id} value={zone.id}>
                  {zone.name}
                </option>
              ))}
            </select>
          </label>
          <button className="btn btn-primary" type="submit" disabled={busy}>
            Entrar a Yunta
          </button>
        </form>
      ) : (
        <form className="stack" onSubmit={sendLink}>
          <label>
            Correo
            <input
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </label>
          <button className="btn btn-primary" type="submit" disabled={busy || sent}>
            {sent ? "Enlace enviado" : "Entrar a Yunta"}
          </button>
          {sent ? <p>Revisa el correo y abre el enlace en este celular.</p> : null}
        </form>
      )}
    </main>
  );
}
