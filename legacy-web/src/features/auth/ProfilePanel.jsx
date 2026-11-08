import { useEffect, useState } from 'react';
import { saveProfile } from './auth';
import { Icon } from '../../shared/components/Icons';

export default function ProfilePanel({ profile, online, onBack, onSave, onToast }) {
  const [form, setForm] = useState({
    display_name: profile.display_name, phone: profile.phone_e164?.replace('+51', '') ?? '',
    latitude: profile.latitude, longitude: profile.longitude,
    location_source: profile.location_source,
  });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  useEffect(() => setForm({
    display_name: profile.display_name, phone: profile.phone_e164?.replace('+51', '') ?? '',
    latitude: profile.latitude, longitude: profile.longitude,
    location_source: profile.location_source,
  }), [profile]);
  function update(key, value) { setForm((current) => ({ ...current, [key]: value })); }

  async function submit(event) {
    event.preventDefault();
    const profileData = { ...form, phone_e164: `+51${form.phone.replace(/\D/g, '')}` };
    if (form.display_name.trim().length < 2) { setError('Revisa tu nombre visible.'); return; }
    if (!/^\+51[0-9]{9}$/.test(profileData.phone_e164)) { setError('Escribe un celular peruano de 9 dígitos.'); return; }
    setBusy(true);
    try {
      await saveProfile(profileData, Boolean(profile.tutorial_completed_at));
      onSave({ ...profileData, tutorial_completed_at: profile.tutorial_completed_at ?? null });
      onToast('Perfil actualizado.');
    }
    catch (cause) { setError(cause.message || 'No se pudo guardar el perfil.'); }
    finally { setBusy(false); }
  }

  return (
    <section className="profile-view">
      <button className="back-button" onClick={onBack}>← Volver al muro</button>
      <div className="profile-heading"><span className="avatar avatar-large">{profile.display_name.slice(0, 1).toUpperCase()}</span>
        <div><h1>Mi perfil</h1><p>Tu sesión se conserva en este navegador.</p></div></div>
      <p className="profile-session-note">Si borras los datos del navegador, perderás el acceso a este perfil anónimo.</p>
      {!online && <p className="field-note">Perfil de solo lectura sin conexión. Tu número no se guarda en la caché del dispositivo.</p>}
      <form className="profile-form form-stack" onSubmit={submit}>
        <label>Nombre visible<input maxLength="60" value={form.display_name} onChange={(event) => update('display_name', event.target.value)} required disabled={!online} /></label>
        <label>Celular<input inputMode="numeric" maxLength="9" value={form.phone} onChange={(event) => update('phone', event.target.value.replace(/\D/g, '').slice(0, 9))} required disabled={!online} /></label>
        <p className="field-note">El número es privado. La demo no verifica por SMS ni lo comparte con vecinos.</p>
        <div className="coordinate-fields">
          <label>Latitud<input inputMode="decimal" value={form.latitude} onChange={(event) => update('latitude', event.target.value)} required disabled={!online} /></label>
          <label>Longitud<input inputMode="decimal" value={form.longitude} onChange={(event) => update('longitude', event.target.value)} required disabled={!online} /></label>
        </div>
        <p className="privacy-note"><Icon name="pin" size={17} /> Tus coordenadas exactas son privadas; Yunta las usa para encontrar avisos a menos de 500 m.</p>
        {error && <p className="form-error" role="alert">{error}</p>}
        <button className="button button-primary" disabled={busy || !online}>{busy ? 'Guardando…' : 'Guardar cambios'}</button>
      </form>
    </section>
  );
}
