import { useState } from 'react';
import PostCard from './PostCard';
import { Icon } from '../../shared/components/Icons';

const categories = [
  { id: 'help', label: 'Ayuda', icon: 'help' },
  { id: 'products_services', label: 'Productos y servicios', icon: 'store' },
  { id: 'emergency', label: 'Emergencias', icon: 'alert' },
];

export default function Wall({ category, onCategory, posts, pending, error, onRefresh, onPublish, onOpen }) {
  const [refreshing, setRefreshing] = useState(false);
  const active = categories.find((item) => item.id === category);

  async function refresh() {
    setRefreshing(true);
    await onRefresh();
    setRefreshing(false);
  }

  return (
    <section className="wall-view">
      <header className="page-heading">
        <div><h1>El muro del barrio</h1><p>Lo que ocurre cerca de ti, a menos de 500 m.</p></div>
        <button className="button button-primary publish-button" onClick={onPublish}>
          <Icon name="plus" /> Publicar
        </button>
      </header>
      <div className="category-tabs" role="tablist" aria-label="Secciones del muro">
        {categories.map((item) => (
          <button key={item.id} role="tab" aria-selected={category === item.id}
            className={category === item.id ? 'category-tab active' : 'category-tab'}
            onClick={() => onCategory(item.id)}>
            <Icon name={item.icon} size={18} /><span>{item.label}</span>
          </button>
        ))}
      </div>
      <div className="wall-heading-row">
        <h2>{active?.label ?? 'Avisos'}</h2>
        <button className="text-button" onClick={refresh} disabled={refreshing}>
          {refreshing ? 'Actualizando…' : 'Actualizar'}
        </button>
      </div>
      {pending.length > 0 && (
        <div className="sync-banner" role="status">
          <span>{pending.length} {pending.length === 1 ? 'aviso espera' : 'avisos esperan'} conexión para publicarse.</span>
          <Icon name="message" size={17} />
        </div>
      )}
      {error && <div className="inline-error" role="alert">{error}</div>}
      {posts.length ? (
        <div className="post-list">{posts.map((post) => <PostCard key={post.id} post={post} onOpen={onOpen} />)}</div>
      ) : (
        <div className="empty-wall">
          <span className="empty-icon"><Icon name={active?.icon ?? 'home'} size={25} /></span>
          <h3>El barrio está tranquilo por ahora.</h3>
          <p>Publica lo que necesitas o comparte algo que pueda ayudar a un vecino.</p>
          <button className="button button-secondary" onClick={onPublish}>Crear el primer aviso</button>
        </div>
      )}
    </section>
  );
}
