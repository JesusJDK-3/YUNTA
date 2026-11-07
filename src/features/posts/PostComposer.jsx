import { useState } from 'react';
import { Icon } from '../../shared/components/Icons';
import { validCoordinates } from '../../services/location';
import { containsPrivateContact } from '../../shared/lib/privacy';

const types = {
  help: [['help_request', 'Necesito ayuda'], ['help_offer', 'Puedo ayudar']],
  products_services: [['product', 'Producto'], ['service', 'Servicio']],
  emergency: [['urgent_request', 'Necesito apoyo urgente'], ['resource_available', 'Tengo un recurso disponible'], ['support_group_available', 'Organizo un grupo de apoyo']],
};

export default function PostComposer({ profile, initialCategory, onClose, onSubmit }) {
  const [category, setCategory] = useState(initialCategory);
  const [type, setType] = useState(types[initialCategory][0][0]);
  const [mode, setMode] = useState('individual');
  const [form, setForm] = useState({ title: '', description: '', area_label: profile.area_label ?? '', latitude: profile.latitude, longitude: profile.longitude });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [otherPlace, setOtherPlace] = useState(false);

  function changeCategory(next) { setCategory(next); setType(types[next][0][0]); }
  function update(key, value) { setForm((current) => ({ ...current, [key]: value })); }
  const fixedGroup = type === 'support_group_available';

  async function submit(event) {
    event.preventDefault();
    if (form.title.trim().length < 4 || form.description.trim().length < 8 || !form.area_label.trim()) {
      setError('Completa el título, la descripción y la zona.'); return;
    }
    if (containsPrivateContact(`${form.title} ${form.description}`)) { setError('No incluyas celulares ni direcciones exactas en el aviso. Compártelos en el chat.'); return; }
    if (!validCoordinates(form.latitude, form.longitude)) { setError('Revisa el punto aproximado del aviso.'); return; }
    setBusy(true);
    try {
      await onSubmit({
        id: crypto.randomUUID(), category, type, title: form.title.trim(),
        description: form.description.trim(), coordination_mode: fixedGroup ? 'group' : mode,
        latitude: Number(form.latitude), longitude: Number(form.longitude), area_label: form.area_label.trim(),
      });
    } catch (cause) { setError(cause.message || 'No se pudo publicar el aviso.'); }
    finally { setBusy(false); }
  }

  return (
    <div className="overlay" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="composer-panel" role="dialog" aria-modal="true" aria-labelledby="composer-title">
        <div className="panel-heading"><div><h2 id="composer-title">Publica en tu barrio</h2><p>Describe lo que ocurre; coordina después en privado.</p></div>
          <button className="icon-button" onClick={onClose} aria-label="Cerrar"><Icon name="close" /></button></div>
        <form className="form-stack" onSubmit={submit}>
          <label>Sección<select value={category} onChange={(event) => changeCategory(event.target.value)}>
            <option value="help">Ayuda</option><option value="products_services">Productos y servicios</option><option value="emergency">Emergencias</option>
          </select></label>
          <label>¿Qué quieres publicar?<select value={type} onChange={(event) => setType(event.target.value)}>
            {types[category].map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select></label>
          {category === 'emergency' && <p className="emergency-note"><Icon name="alert" size={16} /> Los avisos urgentes llevan una etiqueta visible para el barrio.</p>}
          <label>Título<input autoFocus maxLength="100" value={form.title} onChange={(event) => update('title', event.target.value)} required placeholder="Ej. Busco una muleta para prestar" /></label>
          <label>Cuéntanos un poco más<textarea rows="4" maxLength="1200" value={form.description}
            onChange={(event) => update('description', event.target.value)} required placeholder="Añade detalles para que los vecinos sepan cómo ayudar…" /></label>
          <div className="mode-control">
            <p>¿Cómo quieres coordinar?</p>
            <div className="segmented-control">
              <button type="button" className={!fixedGroup && mode === 'individual' ? 'selected' : ''} disabled={fixedGroup} onClick={() => setMode('individual')}>Con una persona</button>
              <button type="button" className={fixedGroup || mode === 'group' ? 'selected' : ''} disabled={fixedGroup} onClick={() => setMode('group')}>En grupo</button>
            </div>
          </div>
          <label className="check-row"><input type="checkbox" checked={otherPlace} onChange={(event) => setOtherPlace(event.target.checked)} /> El aviso es en otro punto</label>
          <label>Zona aproximada del aviso<input maxLength="80" pattern="[^0-9#]*" value={form.area_label} onChange={(event) => update('area_label', event.target.value)} required /></label>
          <p className="field-note">Solo el nombre del barrio. No incluyas celulares ni direcciones exactas en el aviso; compártelos en el chat.</p>
          {otherPlace && <div className="coordinate-fields">
            <label>Latitud<input inputMode="decimal" value={form.latitude} onChange={(event) => update('latitude', event.target.value)} required /></label>
            <label>Longitud<input inputMode="decimal" value={form.longitude} onChange={(event) => update('longitude', event.target.value)} required /></label>
          </div>}
          <p className="field-note">El muro solo muestra zona y distancia aproximadas. La dirección exacta puedes compartirla en el chat.</p>
          {error && <p className="form-error" role="alert">{error}</p>}
          <button className="button button-primary button-wide" disabled={busy}>{busy ? 'Publicando…' : 'Publicar aviso'}</button>
        </form>
      </section>
    </div>
  );
}
