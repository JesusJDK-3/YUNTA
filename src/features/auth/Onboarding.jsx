import { lazy, Suspense, useState } from 'react';
import { ensureSession, saveProfile } from './auth';
import { currentLocation, validCoordinates } from '../../services/location';
import { Icon } from '../../shared/components/Icons';

const LocationPicker = lazy(() => import('./LocationPicker'));

const initial = { display_name: '', phone: '', latitude: '', longitude: '', location_source: 'manual' };

export default function Onboarding({ onComplete, initialProfile }) {
  const [form, setForm] = useState(initialProfile ? {
    display_name: initialProfile.display_name ?? '',
    phone: initialProfile.phone_e164?.replace('+51', '') ?? '',
    latitude: initialProfile.latitude ?? '', longitude: initialProfile.longitude ?? '',
    location_source: initialProfile.location_source ?? 'manual',
  } : initial);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [locating, setLocating] = useState(false);
  const [mapOpen, setMapOpen] = useState(false);

  function update(key, value) { setForm((current) => ({ ...current, [key]: value })); }

  async function useGps() {
    setLocating(true);
    try {
      const point = await currentLocation();
      setForm((current) => ({ ...current, ...point, location_source: 'gps' }));
      setError('');
    } catch (cause) { setError(cause.message); }
    finally { setLocating(false); }
  }

  function selectMapPoint(point) {
    setForm((current) => ({ ...current, ...point, location_source: 'manual' }));
    setMapOpen(false);
    setError('');
  }

  async function submit(event) {
    event.preventDefault();
    const phone = `+51${form.phone.replace(/\D/g, '')}`;
    if (!form.display_name.trim() || !validCoordinates(form.latitude, form.longitude)) {
      setError('Completa tu nombre y selecciona tu ubicación.');
      return;
    }
    if (form.display_name.trim().length < 2) { setError('El nombre visible debe tener al menos 2 caracteres.'); return; }
    if (!/^\+51[0-9]{9}$/.test(phone)) { setError('Escribe un celular peruano de 9 dígitos.'); return; }
    setBusy(true);
    try {
      await ensureSession(form.display_name);
      const profile = {
        display_name: form.display_name.trim(), phone_e164: phone,
        latitude: Number(form.latitude),
        longitude: Number(form.longitude), location_source: form.location_source,
      };
      await saveProfile(profile, Boolean(initialProfile?.tutorial_completed_at));
      onComplete(profile);
    } catch (cause) { setError(cause.message || 'No se pudo guardar el registro.'); }
    finally { setBusy(false); }
  }

  return (
    <main className="welcome-screen">
      <section className="welcome-card">
        <div className="welcome-brand"><img className="welcome-logo" src="/icons/yunta.svg" alt="" /><span>Yunta</span></div>
        <header className="welcome-intro"><h1>¡Hola, vecino!</h1><p>Conecta con vecinos a 500 m de ti.</p></header>
        <form className="form-stack onboarding-form" onSubmit={submit}>
          <label>Tu nombre<input autoComplete="name" maxLength="60" value={form.display_name}
            onChange={(event) => update('display_name', event.target.value)} required placeholder="¿Cómo te llamas?" /></label>
          <label>Número<input inputMode="numeric" autoComplete="tel-national" maxLength="9"
            value={form.phone} onChange={(event) => update('phone', event.target.value.replace(/\D/g, '').slice(0, 9))}
            required placeholder="Escribe tu número" /></label>
          <div className="onboarding-location">
            <h2>Ubicación</h2>
            <button type="button" className="button button-secondary location-button" onClick={useGps} disabled={locating}>
              <Icon name="pin" size={24} /> {locating ? 'Buscando…' : 'Usar mi ubicación'}
            </button>
            <button type="button" className="text-button location-map-link" onClick={() => setMapOpen(true)}>Elegir en el mapa</button>
            {validCoordinates(form.latitude, form.longitude) && <span className="location-ready"><Icon name="check" size={17} /> Ubicación lista</span>}
          </div>
          {error && <p className="form-error" role="alert">{error}</p>}
          <button className="button button-primary button-wide" disabled={busy}>
            {busy ? 'Guardando…' : 'Entrar a Yunta'}
          </button>
        </form>
      </section>
      {mapOpen && <Suspense fallback={<div className="location-map-backdrop">
        <section className="location-map-dialog" role="status">Cargando mapa…</section>
      </div>}>
        <LocationPicker initialLocation={{ latitude: form.latitude, longitude: form.longitude }}
          onClose={() => setMapOpen(false)} onSelect={selectMapPoint} />
      </Suspense>}
    </main>
  );
}
