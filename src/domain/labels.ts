import type { HelpType, Intent } from "./types";

export const HELP_LABEL: Record<HelpType, string> = {
  herramienta: "Herramienta",
  ayuda_temporal: "Ayuda temporal",
  donacion: "Donación",
  habilidad: "Habilidad",
  movilidad: "Movilidad",
};

export const INTENT_LABEL: Record<Intent, string> = {
  pido_ayuda: "Pido ayuda",
  ofrezco_ayuda: "Ofrezco ayuda ahora",
  producto: "Ofrezco un producto",
  servicio: "Ofrezco un oficio",
  emergencia_persona: "Emergencia de una persona",
  emergencia_cuadra: "Emergencia de una cuadra",
  emergencia_recurso: "Recurso para la emergencia",
  grupo_apoyo: "Grupo de apoyo",
};

export const STATUS_LABEL: Record<string, string> = {
  activo: "Activo",
  retirado: "Retirado",
  abierto: "Abierto",
  en_coordinacion: "En coordinación",
  resuelto: "Resuelto",
  cancelado: "Cancelado",
};

export const MODE_LABEL: Record<string, string> = {
  individual: "Entre dos",
  grupal: "En grupo",
};

export function statusLabel(status: string): string {
  return STATUS_LABEL[status] ?? status;
}

export function modeLabel(mode: string | null): string | null {
  if (!mode) return null;
  return MODE_LABEL[mode] ?? mode;
}
