import { useState } from 'react';
import PostCard from './PostCard';
import NeighborhoodArt from './NeighborhoodArt';
import { Icon } from '../../shared/components/Icons';

const categories = [
  { id: 'help', label: 'Ayuda', icon: 'help' },
  { id: 'products_services', label: 'Productos y servicios', icon: 'store' },
  { id: 'emergency', label: 'Emergencias', icon: 'alert' },
];

export default function Wall({ category, onCategory, posts, pending, error, onRefresh, onPublish, onOpen }) {
  const [refreshing, setRefreshing] = useState(false);
  const active = categories.find((item) => item.id === category);
  const visiblePosts = posts.filter((post) => post.category === category);
  const emergencyCount = posts.filter((post) => post.category === 'emergency').length;
  const sectionTitle = category === 'help' ? 'Ayuda vecinal' : active?.label ?? 'Avisos cercanos';
  const emptyCategory = active ? active.label.toLowerCase() : 'esta sección';

  async function refresh() {
    setRefreshing(true);
    try { await onRefresh(); }
    finally { setRefreshing(false); }
  }

  return (
    <section className="wall-view">
      <header className="wall-hero">
        <div className="wall-hero-copy">
          <h1>Cerca de ti</h1>
          <div className="wall-hero-tools">
            <span className="location-range-pill"><Icon name="pin" size={19} /> Radio de 500 m</span>
          </div>
        </div>
        <NeighborhoodArt />
      </header>
      <div className="category-tabs" role="group" aria-label="Filtrar avisos por categoría">
        {categories.map((item) => (
          <button type="button" key={item.id} aria-pressed={category === item.id}
            className={category === item.id ? 'category-tab active' : 'category-tab'}
            onClick={() => onCategory(item.id)}>
            <Icon name={item.icon} size={18} /><span>{item.label}</span>
          </button>
        ))}
      </div>
      {emergencyCount > 0 && <button type="button" className="emergency-alert-banner"
        onClick={() => onCategory('emergency')}>
        <span><Icon name="alert" size={24} /> {emergencyCount} {emergencyCount === 1 ? 'aviso' : 'avisos'} de emergencia cerca</span>
        <Icon name="arrow-right" size={24} />
      </button>}
      <div className="wall-heading-row">
        <h2>{sectionTitle}</h2>
        <button className="wall-refresh" onClick={refresh} disabled={refreshing} aria-label="Actualizar avisos">
          <Icon name="refresh" size={18} />
        </button>
      </div>
      {pending.length > 0 && (
        <div className="sync-banner" role="status">
          <span>{pending.length} {pending.length === 1 ? 'aviso espera' : 'avisos esperan'} conexión para publicarse.</span>
          <Icon name="message" size={17} />
        </div>
      )}
      {error && <div className="inline-error" role="alert">{error}</div>}
      {visiblePosts.length ? (
        <div className="post-list">{visiblePosts.map((post) => <PostCard key={post.id} post={post} onOpen={onOpen} />)}</div>
      ) : (
        <div className="empty-wall">
          <h3>Aún no hay avisos de {emptyCategory} cerca.</h3>
          <p>Publica lo que necesitas o comparte algo que pueda ayudar a un vecino a menos de 500 m.</p>
        </div>
      )}
      <footer className="wall-publish-footer">
        <button type="button" className="button button-primary publish-button" onClick={onPublish}>
          <Icon name="plus" /> Publicar
        </button>
      </footer>
    </section>
  );
}
