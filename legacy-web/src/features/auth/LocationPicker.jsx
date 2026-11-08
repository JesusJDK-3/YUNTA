import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Icon } from '../../shared/components/Icons';
import { validCoordinates } from '../../services/location';

const peruCenter = [-9.19, -75.015];

export default function LocationPicker({ initialLocation, onClose, onSelect }) {
  const mapNode = useRef(null);
  const [point, setPoint] = useState(validCoordinates(initialLocation?.latitude, initialLocation?.longitude)
    ? { latitude: Number(initialLocation.latitude), longitude: Number(initialLocation.longitude) } : null);

  useEffect(() => {
    const hasPoint = validCoordinates(initialLocation?.latitude, initialLocation?.longitude);
    const center = hasPoint ? [Number(initialLocation.latitude), Number(initialLocation.longitude)] : peruCenter;
    const map = L.map(mapNode.current, { scrollWheelZoom: true }).setView(center, hasPoint ? 15 : 5);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19, attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);
    let marker = null;
    const placeMarker = (latitude, longitude) => {
      if (!marker) marker = L.marker([latitude, longitude], {
        icon: L.divIcon({ className: 'location-map-marker', html: '<span></span>', iconSize: [24, 24], iconAnchor: [12, 12] }),
      }).addTo(map);
      else marker.setLatLng([latitude, longitude]);
    };
    if (hasPoint) placeMarker(center[0], center[1]);
    map.on('click', ({ latlng }) => {
      const next = { latitude: latlng.lat, longitude: latlng.lng };
      setPoint(next);
      placeMarker(next.latitude, next.longitude);
    });
    return () => map.remove();
  }, [initialLocation]);

  return (
    <div className="location-map-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="location-map-dialog" role="dialog" aria-modal="true" aria-labelledby="location-map-title">
        <div className="location-map-heading">
          <div><h2 id="location-map-title">Elegir en el mapa</h2><p>Toca el mapa para marcar tu ubicación.</p></div>
          <button type="button" className="icon-button" onClick={onClose} aria-label="Cerrar mapa"><Icon name="close" /></button>
        </div>
        <div className="location-map-surface" ref={mapNode} aria-label="Mapa para elegir una ubicación" />
        <p className="map-attribution">OpenStreetMap recibe solicitudes del mapa, tu IP y puede inferir la zona mostrada. © OpenStreetMap contributors</p>
        <button type="button" className="button button-primary button-wide" disabled={!point}
          onClick={() => onSelect(point)}>Usar este punto</button>
      </section>
    </div>
  );
}
