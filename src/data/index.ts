/**
 * Yunta habla solo con Supabase. Sin las dos variables públicas no arranca.
 */

import { withOutbox } from "./outbox";
import { createSupabaseApi } from "./supabase-api";
import type { YuntaApi } from "./api";

export type { YuntaApi, ViewerPoint } from "./api";

export function readSupabaseConfig(): { url: string; key: string } | null {
  const url = import.meta.env.VITE_SUPABASE_URL?.trim() ?? "";
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY?.trim() ?? "";
  if (!url || !key) return null;
  return { url, key };
}

export function createYuntaApi(url: string, key: string): YuntaApi {
  return withOutbox(createSupabaseApi(url, key), window.localStorage);
}
