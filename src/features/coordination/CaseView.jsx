import { useState } from 'react';
import Chat from '../chat/Chat';
import { Icon } from '../../shared/components/Icons';
import { postTypeLabels, postStatusLabels } from '../../shared/lib/labels';
import { containsPrivateContact } from '../../shared/lib/privacy';

export default function CaseView({ post, userId, onBack, onRefresh, onToast }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [score, setScore] = useState(5);
  const [comment, setComment] = useState('');
  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState({ title: post.title, description: post.description, area_label: post.area_label });
  const owner = post.author_id === userId;
  const accepted = post.my_membership === 'accepted' || post.my_membership === 'active';
  const canRate = post.status === 'resolved' && post.coordination_mode === 'individual' && !post.my_rating && (
    (owner && ['help_request', 'urgent_request'].includes(post.type)) || (!owner && accepted && !['help_request', 'urgent_request'].includes(post.type))
  );
  const canChat = owner ? post.status === 'coordinating' || (post.status === 'resolved' && post.member_count > 0)
    : accepted && post.status !== 'cancelled';
  const ad = post.category === 'products_services';

  async function action(name, args = {}) {
    setBusy(true); setError('');
    try { await onRefresh(name, { p_post_id: post.id, ...args }); onToast('Listo, el caso se actualizó.'); }
    catch (cause) { setError(cause.message || 'No se pudo completar la acción.'); }
    finally { setBusy(false); }
  }

  async function rate(event) {
    event.preventDefault();
    await action('rate_provider', { p_score: Number(score), p_comment: comment || null });
  }

  async function edit(event) {
    event.preventDefault();
    if (containsPrivateContact(`${editForm.title} ${editForm.description}`)) {
      setError('No incluyas celulares ni direcciones exactas en el anuncio.'); return;
    }
    await action('edit_local_ad', {
      p_title: editForm.title, p_description: editForm.description, p_area_label: editForm.area_label,
    });
    setEditing(false);
  }

  return (
    <section className="case-view">
      <button className="back-button" onClick={onBack}>← Volver al muro</button>
      <article className="case-content">
        <div className="case-topline">
          <span className={post.category === 'emergency' ? 'emergency-label' : 'post-type'}>
          {post.category === 'emergency' && <Icon name="alert" size={16} />}{postTypeLabels[post.type] ?? 'Aviso vecinal'}
          </span><span className={`status-pill status-${post.status}`}>{postStatusLabels[post.status]}</span>
        </div>
        <h1>{post.title}</h1>
        <p className="case-description">{post.description}</p>
        <div className="case-facts"><span><Icon name="pin" size={17} />{post.area_label} · a {post.distance_m} m</span>
          <span><Icon name="person" size={17} />{post.author_name}</span>
          <span>{post.coordination_mode === 'group' ? `${post.member_count} personas coordinando` : 'Coordinación individual'}</span></div>
        {error && <p className="form-error" role="alert">{error}</p>}

        {owner && post.offers?.length > 0 && post.status !== 'cancelled' && (
          <section className="offers-list"><h2>Vecinos que se ofrecieron</h2>
            {post.offers.map((offer) => <div className="offer-row" key={offer.user_id}>
              <span>{offer.display_name}</span>
              <button className="button button-secondary" disabled={busy} onClick={() => action('accept_post_offer', { p_user_id: offer.user_id })}>Elegir</button>
            </div>)}
          </section>
        )}

        {!owner && ['open', 'coordinating'].includes(post.status) && !accepted && post.my_membership !== 'pending' && (
          <button className="button button-help" disabled={busy} onClick={() => action('join_post')}>
            {post.coordination_mode === 'group' ? 'Unirme a la coordinación' : post.type === 'service' ? 'Solicitar este servicio' : post.type === 'product' ? 'Consultar producto' : 'Puedo ayudar'}
          </button>
        )}
        {!owner && post.my_membership === 'pending' && <p className="waiting-note">Tu solicitud está pendiente de confirmación por quien publicó el aviso.</p>}
        {ad && !owner && !post.has_recommended && <button className="text-button recommend-button" disabled={busy} onClick={() => action('recommend_ad')}>Recomendar este anuncio</button>}
        {ad && post.has_recommended && <p className="field-note">Ya recomendaste este anuncio.</p>}

        {owner && ['open', 'coordinating'].includes(post.status) && <div className="case-actions">
          {post.coordination_mode === 'individual' && post.status === 'coordinating' &&
            <button className="button button-secondary" disabled={busy} onClick={() => action('reopen_post')}>Buscar a otra persona</button>}
          <button className="button button-help" disabled={busy} onClick={() => action('resolve_post')}>Marcar como resuelto</button>
          <button className="text-button danger-text" disabled={busy} onClick={() => action('cancel_post')}>Retirar aviso</button>
        </div>}
        {owner && ad && ['open', 'coordinating'].includes(post.status) && <>
          <button className="text-button" onClick={() => setEditing((value) => !value)}>{editing ? 'Cerrar edición' : 'Editar anuncio'}</button>
          {editing && <form className="edit-ad-form" onSubmit={edit}>
            <label>Título<input maxLength="100" value={editForm.title} onChange={(event) => setEditForm((current) => ({ ...current, title: event.target.value }))} required /></label>
            <label>Descripción<textarea maxLength="1200" value={editForm.description} onChange={(event) => setEditForm((current) => ({ ...current, description: event.target.value }))} required /></label>
            <label>Barrio aproximado<input maxLength="80" pattern="[^0-9#]*" value={editForm.area_label} onChange={(event) => setEditForm((current) => ({ ...current, area_label: event.target.value }))} required /></label>
            <button className="button button-primary" disabled={busy}>Guardar anuncio</button>
          </form>}
        </>}

        {canChat && <Chat post={post} userId={userId} />}
        {canRate && <form className="rating-form" onSubmit={rate}>
          <h2>¿Cómo fue la ayuda?</h2><p>Tu valoración ayuda a que el barrio recomiende con confianza.</p>
          <label>Calificación<select value={score} onChange={(event) => setScore(event.target.value)}>
            <option value="5">5 · Excelente</option><option value="4">4 · Muy bien</option><option value="3">3 · Bien</option><option value="2">2 · Regular</option><option value="1">1 · Mala experiencia</option>
          </select></label>
          <label>Comentario opcional<textarea maxLength="500" value={comment} onChange={(event) => setComment(event.target.value)} placeholder="Comparte un comentario breve" /></label>
          <button className="button button-primary" disabled={busy}>Enviar valoración</button>
        </form>}
      </article>
    </section>
  );
}
