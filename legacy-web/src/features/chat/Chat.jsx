import { useEffect, useState } from 'react';
import { loadMessages, sendMessage, watchMessages } from '../../services/yuntaApi';
import { Icon } from '../../shared/components/Icons';

export default function Chat({ post, userId, online }) {
  const [messages, setMessages] = useState([]);
  const [body, setBody] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const canSend = online && ['open', 'coordinating'].includes(post.status);

  useEffect(() => {
    let active = true;
    if (!online) { setError('Conéctate para consultar el chat.'); return () => { active = false; }; }
    setError('');
    const stop = watchMessages(post.id, (message) => {
      setMessages((items) => items.some((item) => item.id === message.id) ? items : [...items, message]);
    });
    loadMessages(post.id).then((items) => { if (active) setMessages(items); })
      .catch((cause) => { if (active) setError(cause.message); });
    return () => { active = false; stop(); };
  }, [online, post.id]);

  async function submit(event) {
    event.preventDefault();
    if (!body.trim()) return;
    setBusy(true);
    try { await sendMessage(post.id, userId, body); setBody(''); setError(''); }
    catch (cause) { setError(cause.message || 'No se pudo enviar el mensaje.'); }
    finally { setBusy(false); }
  }

  return (
    <section className="chat-panel" aria-label="Chat de coordinación">
      <div className="chat-heading"><Icon name="message" /><div><strong>Coordinación</strong><span>Chat privado de este aviso</span></div></div>
      {error && <p className="form-error" role="alert">{error}</p>}
      <div className="message-list" aria-live="polite">
        {messages.length === 0 && <p className="chat-empty">Aún no hay mensajes. Acuerden aquí el siguiente paso.</p>}
        {messages.map((message) => (
          <article key={message.id} className={message.sender_id === userId ? 'message-bubble own' : 'message-bubble'}>
            <p>{message.body}</p>
            <time>{new Date(message.created_at).toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' })}</time>
          </article>
        ))}
      </div>
      {canSend ? <form className="message-form" onSubmit={submit}>
        <label className="sr-only" htmlFor="chat-message">Escribe un mensaje</label>
        <input id="chat-message" maxLength="2000" value={body} onChange={(event) => setBody(event.target.value)} placeholder="Escribe un mensaje…" />
        <button className="button button-primary" disabled={busy || !body.trim()} aria-label="Enviar mensaje">Enviar</button>
      </form> : <p className="field-note">El chat necesita conexión. En casos cerrados queda disponible para consulta.</p>}
    </section>
  );
}
