import { Icon } from '../../shared/components/Icons';
import { postStatusLabels, postTypeLabels } from '../../shared/lib/labels';

const typeIcons = {
  help_request: 'help',
  help_offer: 'heart',
  product: 'store',
  service: 'store',
  urgent_request: 'alert',
  resource_available: 'pin',
  support_group_available: 'person',
};

export default function PostCard({ post, onOpen }) {
  const emergency = post.category === 'emergency';
  const active = ['open', 'coordinating'].includes(post.status);
  const distance = post.distance_m == null ? 'Sin conexión' : 'A ' + post.distance_m + ' m';

  return (
    <button className={'post-card' + (emergency ? ' post-card-emergency' : '')} onClick={() => onOpen(post)}>
      <span className="post-card-art"><Icon name={typeIcons[post.type] ?? 'help'} size={30} /></span>
      <span className="post-card-body">
        <span className="post-card-topline">
          <span className={'post-type' + (emergency ? ' emergency-label' : '')}>
            {emergency && <Icon name="alert" size={14} />}{postTypeLabels[post.type] ?? 'Aviso vecinal'}
          </span>
          <span className="post-card-mode">{post.coordination_mode === 'group' ? 'Grupal' : 'Individual'}</span>
        </span>
        <strong>{post.title}</strong>
        <span className="post-card-description">{post.description}</span>
        <span className="post-card-facts">
          <span><Icon name="pin" size={16} />{post.area_label ? post.area_label + ' · ' + distance : distance}</span>
          <span className={'post-status-dot' + (active ? ' is-active' : '')}>
            {postStatusLabels[post.status] ?? 'Abierto'}
          </span>
        </span>
        {post.category === 'products_services' && <span className="post-card-author">
          {post.recommendation_count} recomendaciones vecinales
        </span>}
      </span>
      <Icon name="chevron-right" size={22} className="post-card-arrow" />
    </button>
  );
}
