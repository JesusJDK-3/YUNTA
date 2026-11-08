/**
 * Cada opción es el aviso completo.
 * En la pantalla basta un toque para elegirla: no hay un segundo menú de tipo.
 */

import type { HelpType, Intent } from "./types";

export interface PublishChoice {
  id: string;
  intent: Intent;
  helpType?: HelpType;
  label: string;
  group: "favor" | "directorio" | "emergencia";
}

export const PUBLISH_CHOICES: PublishChoice[] = [
  { id: "pido-herramienta", intent: "pido_ayuda", helpType: "herramienta", label: "Pido una herramienta", group: "favor" },
  { id: "presto-herramienta", intent: "ofrezco_ayuda", helpType: "herramienta", label: "Presto una herramienta", group: "favor" },
  { id: "pido-temporal", intent: "pido_ayuda", helpType: "ayuda_temporal", label: "Pido ayuda temporal", group: "favor" },
  { id: "ofrezco-temporal", intent: "ofrezco_ayuda", helpType: "ayuda_temporal", label: "Ofrezco ayuda temporal", group: "favor" },
  { id: "pido-donacion", intent: "pido_ayuda", helpType: "donacion", label: "Pido una donación", group: "favor" },
  { id: "ofrezco-donacion", intent: "ofrezco_ayuda", helpType: "donacion", label: "Ofrezco una donación", group: "favor" },
  { id: "pido-habilidad", intent: "pido_ayuda", helpType: "habilidad", label: "Pido una habilidad", group: "favor" },
  { id: "ofrezco-habilidad", intent: "ofrezco_ayuda", helpType: "habilidad", label: "Ofrezco una habilidad", group: "favor" },
  { id: "pido-movilidad", intent: "pido_ayuda", helpType: "movilidad", label: "Pido movilidad", group: "favor" },
  { id: "ofrezco-movilidad", intent: "ofrezco_ayuda", helpType: "movilidad", label: "Ofrezco movilidad", group: "favor" },
  { id: "oficio", intent: "servicio", label: "Ofrezco un oficio", group: "directorio" },
  { id: "producto", intent: "producto", label: "Ofrezco un producto", group: "directorio" },
  { id: "persona", intent: "emergencia_persona", label: "Emergencia de una persona", group: "emergencia" },
  { id: "cuadra", intent: "emergencia_cuadra", label: "Emergencia de una cuadra", group: "emergencia" },
  { id: "recurso", intent: "emergencia_recurso", label: "Recurso para la emergencia", group: "emergencia" },
  { id: "grupo", intent: "grupo_apoyo", label: "Grupo de apoyo", group: "emergencia" },
];

export const DEFAULT_PUBLISH_CHOICE = "pido-herramienta";

export function publishChoice(id: string): PublishChoice {
  return PUBLISH_CHOICES.find((choice) => choice.id === id) ?? PUBLISH_CHOICES[0];
}
