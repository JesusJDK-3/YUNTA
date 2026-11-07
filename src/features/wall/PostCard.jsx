import { Icon } from '../../shared/components/Icons';
import { postStatusLabels, postTypeLabels } from '../../shared/lib/labels';

export default function PostCard({ post, onOpen }) {
  const emergency = post.category === 'emergency';
  return (
    <button className={`post-card${emergency ? ' post-card-emergency' : ''}`} onClick={() => onOpen(post)}>
      <span className="post-card-topline">
        <span className={`post-type${emergency ? ' emergency-label' : ''}`}>
          {emergency && <Icon name="alert" size={15} />}{postTypeLabels[post.type] ?? 'Aviso vecinal'}
        </span>
        <span className="post-distance">{post.distance_m == null ? 'Sin conexión' : `A ${post.distance_m} m`}</span>
      </span>
      <strong>{post.title}</strong>
      <span className="post-card-description">{post.description}</span>
      <span className="post-card-meta">
        <span>{post.area_label}</span><span>{postStatusLabels[post.status] ?? 'Abierto'}</span>
        <span>{post.coordination_mode === 'group' ? 'Grupal' : 'Individual'}</span>
      </span>
      {post.category === 'products_services' && <span className="post-card-author">{post.recommendation_count} recomendaciones vecinales</span>}
      <span className="post-card-author">{post.author_name ? `Por ${post.author_name}` : 'Aviso pendiente'}</span>
    </button>
  );
}
