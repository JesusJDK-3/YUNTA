export function currentLocation() {
  if (!navigator.geolocation) return Promise.reject(new Error('Este navegador no ofrece ubicación automática.'));
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => resolve({ latitude: coords.latitude, longitude: coords.longitude }),
      () => reject(new Error('No se pudo leer la ubicación. Puedes marcarla manualmente.')),
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 60000 },
    );
  });
}

export function validCoordinates(latitude, longitude) {
  return Number.isFinite(Number(latitude)) && Number(latitude) >= -90 && Number(latitude) <= 90
    && Number.isFinite(Number(longitude)) && Number(longitude) >= -180 && Number(longitude) <= 180;
}
