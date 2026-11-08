/**
 * En una emergencia el muro se parte en tres.
 * El tablero humanitario junta a la persona y a la cuadra.
 * La economía solidaria es solo el recurso crítico.
 * Los grupos de apoyo quedan en su propio directorio.
 */

import type { FeedItem } from "./types";

export interface EmergencyBoards {
  humanitario: FeedItem[];
  solidaria: FeedItem[];
  apoyo: FeedItem[];
}

export function splitEmergencyBoard(items: FeedItem[]): EmergencyBoards {
  const humanitario: FeedItem[] = [];
  const solidaria: FeedItem[] = [];
  const apoyo: FeedItem[] = [];
  for (const item of items) {
    if (item.category === "grupo_de_apoyo" || item.type === "grupo_de_apoyo") apoyo.push(item);
    else if (item.type === "recurso") solidaria.push(item);
    else humanitario.push(item);
  }
  return { humanitario, solidaria, apoyo };
}
