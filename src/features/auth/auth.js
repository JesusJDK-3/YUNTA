import { isSupabaseConfigured, supabase } from '../../services/supabase/client';

export async function ensureSession(displayName) {
  if (!isSupabaseConfigured) throw new Error('Yunta aún no está conectada a Supabase.');
  const { data: current } = await supabase.auth.getSession();
  if (current.session) return current.session;
  const { data, error } = await supabase.auth.signInAnonymously({
    options: { data: { display_name: displayName.trim() } },
  });
  if (error) throw error;
  return data.session;
}

export async function saveProfile(profile, tutorialCompleted = false) {
  const { error } = await supabase.rpc('save_my_profile', {
    p_display_name: profile.display_name.trim(),
    p_phone_e164: profile.phone_e164,
    p_latitude: Number(profile.latitude),
    p_longitude: Number(profile.longitude),
    p_location_source: profile.location_source,
    p_tutorial_completed: tutorialCompleted,
  });
  if (error) throw error;
}

export async function getProfile() {
  const { data, error } = await supabase.rpc('get_my_profile');
  if (error) throw error;
  return data;
}

export function subscribeToSession(callback) {
  return supabase.auth.onAuthStateChange((_event, session) => callback(session));
}
