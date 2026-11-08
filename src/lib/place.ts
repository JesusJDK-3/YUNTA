import { useCallback, useState } from "react";
import type { ViewerPoint } from "../data/api";

export type PlaceStatus = "idle" | "loading" | "ready" | "denied";

/**
 * El punto vive solo en memoria.
 * No se escribe en localStorage ni en el perfil: sirve para ordenar
 * y para el radio de 500 m, y se olvida al cerrar la pestaña.
 * enableHighAccuracy va apagado a propósito: llega antes y es menos fino.
 */
export function usePlace() {
  const [point, setPoint] = useState<ViewerPoint | null>(null);
  const [status, setStatus] = useState<PlaceStatus>("idle");

  const ask = useCallback(() => {
    if (!("geolocation" in navigator)) {
      setStatus("denied");
      return;
    }
    setStatus("loading");
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setPoint({ lat: position.coords.latitude, lng: position.coords.longitude });
        setStatus("ready");
      },
      () => {
        setPoint(null);
        setStatus("denied");
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 60_000 },
    );
  }, []);

  return { point, status, ask };
}
