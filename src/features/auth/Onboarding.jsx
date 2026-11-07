import { useState } from 'react';
import { ensureSession, saveProfile } from './auth';
import { currentLocation, validCoordinates } from '../../services/location';
import { Icon } from '../../shared/components/Icons';
import { isApproximateArea } from '../../shared/lib/privacy';

const initial = { display_name: '', phone: '', area_label: '', latitude: '', longitude: '', location_source: 'manual' };

export default function Onboarding({ onComplete, initialProfile }) {
  const [form, setForm] = useState(initialProfile ? {
    display_name: initialProfile.display_name ?? '',
    phone: initialProfile.phone_e164?.replace('+51', '') ?? '',
    area_label: initialProfile.area_label ?? '',
    latitude: initialProfile.latitude ?? '', longitude: initialProfile.longitude ?? '',
    location_source: initialProfile.location_source ?? 'manual',
  } : initial);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [locating, setLocating] = useState(false);
  const [manualLocation, setManualLocation] = useState(false);

  function update(key, value) { setForm((current) => ({ ...current, [key]: value })); }

  async function useGps() {
    setLocating(true);
    try {
      const point = await currentLocation();
      setForm((current) => ({ ...current, ...point, location_source: 'gps' }));
      setManualLocation(false);
      setError('');
    } catch (cause) { setError(cause.message); }
    finally { setLocating(false); }
  }

  async function submit(event) {
    event.preventDefault();
    const phone = `+51${form.phone.replace(/\D/g, '')}`;
    if (!form.display_name.trim() || !form.area_label.trim() || !validCoordinates(form.latitude, form.longitude)) {
      setError('Completa tu nombre, zona y un punto válido del mapa.');
      return;
    }
    if (form.display_name.trim().length < 2) { setError('El nombre visible debe tener al menos 2 caracteres.'); return; }
    if (!isApproximateArea(form.area_label)) { setError('Escribe solo el nombre del barrio, sin calles ni números.'); return; }
    if (!/^\+51[0-9]{9}$/.test(phone)) { setError('Escribe un celular peruano de 9 dígitos.'); return; }
    setBusy(true);
    try {
      await ensureSession(form.display_name);
      const profile = {
        display_name: form.display_name.trim(), phone_e164: phone,
        area_label: form.area_label.trim(), latitude: Number(form.latitude),
        longitude: Number(form.longitude), location_source: form.location_source,
      };
      await saveProfile(profile, Boolean(initialProfile?.tutorial_completed_at));
      onComplete(profile);
    } catch (cause) { setError(cause.message || 'No se pudo guardar el registro.'); }
    finally { setBusy(false); }
  }

  return (
    <main className="welcome-screen">
      <img className="welcome-logo" src="/icons/yunta.svg" alt="" />
      <section className="welcome-card">
        <h1 className="sr-only">Registro en Yunta</h1>
        <form className="form-stack" onSubmit={submit}>
          <div className="form-stack">
            <label>Ubicación<input maxLength="80" pattern="[^0-9#]*" value={form.area_label}
              onChange={(event) => update('area_label', event.target.value)} required placeholder="Nombre de tu barrio" /></label>
            <div className="location-actions">
              <button type="button" className="button button-secondary" onClick={useGps} disabled={locating}>
                <Icon name="pin" /> {locating ? 'Buscando…' : 'Usar mi ubicación actual'}
              </button>
              <span>{form.location_source === 'gps' ? 'Ubicación actual lista' : 'Selecciona tu ubicación'}</span>
            </div>
            <button type="button" className="text-button" onClick={() => setManualLocation((value) => !value)}>
              {manualLocation ? 'Ocultar coordenadas' : 'Ingresar coordenadas manualmente'}
            </button>
            {manualLocation && <div className="coordinate-fields">
              <label>Latitud<input inputMode="decimal" value={form.latitude} onChange={(event) => update('latitude', event.target.value)} required /></label>
              <label>Longitud<input inputMode="decimal" value={form.longitude} onChange={(event) => update('longitude', event.target.value)} required /></label>
            </div>}
          </div>
          <label>Celular peruano<input inputMode="numeric" autoComplete="tel-national" maxLength="9"
            value={form.phone} onChange={(event) => update('phone', event.target.value.replace(/\D/g, '').slice(0, 9))}
            required /></label>
          <label>Nombre visible<input autoComplete="name" maxLength="60" value={form.display_name}
            onChange={(event) => update('display_name', event.target.value)} required placeholder="Tu nombre" /></label>
          {error && <p className="form-error" role="alert">{error}</p>}
          <button className="button button-primary button-wide" disabled={busy}>
            {busy ? 'Guardando…' : 'Entrar al barrio'}
          </button>
        </form>
      </section>
    </main>
  );
}
