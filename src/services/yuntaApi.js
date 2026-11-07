import { supabase } from './supabase/client';
import { listPendingPosts, removePendingPost, savePendingPost } from './offline/outbox';

export async function loadNearby(category = null) {
  const { data, error } = await supabase.rpc('nearby_posts', { p_category: category });
  if (error) throw error;
  return data ?? [];
}

export async function loadPost(id) {
  const { data, error } = await supabase.rpc('get_post_detail', { p_post_id: id });
  if (error) throw error;
  return data;
}

export async function createPost(post) {
  if (!navigator.onLine) {
    await savePendingPost(post);
    return { ...post, status: 'pending' };
  }
  try {
    const { data, error } = await supabase.rpc('create_post', {
      p_id: post.id, p_category: post.category, p_type: post.type,
      p_title: post.title, p_description: post.description,
      p_mode: post.coordination_mode, p_latitude: post.latitude,
      p_longitude: post.longitude, p_area_label: post.area_label,
    });
    if (error) throw error;
    return { ...post, id: data, status: 'open' };
  } catch (cause) {
    if (!navigator.onLine || cause instanceof TypeError) {
      await savePendingPost(post);
      return { ...post, status: 'pending' };
    }
    throw cause;
  }
}

export async function syncPendingPosts() {
  if (!navigator.onLine) return 0;
  const pending = await listPendingPosts();
  let synced = 0;
  for (const post of pending) {
    try {
      const { error } = await supabase.rpc('create_post', {
        p_id: post.id, p_category: post.category, p_type: post.type,
        p_title: post.title, p_description: post.description,
        p_mode: post.coordination_mode, p_latitude: post.latitude,
        p_longitude: post.longitude, p_area_label: post.area_label,
      });
      if (error) continue;
      await removePendingPost(post.id);
      synced += 1;
    } catch { break; }
  }
  return synced;
}

export async function postAction(name, args) {
  const { data, error } = await supabase.rpc(name, args);
  if (error) throw error;
  return data;
}

export async function loadMessages(postId) {
  const { data, error } = await supabase.from('messages').select('id, sender_id, body, created_at')
    .eq('post_id', postId).order('created_at', { ascending: true }).limit(200);
  if (error) throw error;
  return data ?? [];
}

export async function sendMessage(postId, senderId, body) {
  const { error } = await supabase.from('messages').insert({ post_id: postId, sender_id: senderId, body: body.trim() });
  if (error) throw error;
}

export function watchMessages(postId, onMessage) {
  const channel = supabase.channel(`yunta-chat-${postId}`)
    .on('postgres_changes', {
      event: 'INSERT', schema: 'public', table: 'messages', filter: `post_id=eq.${postId}`,
    }, ({ new: message }) => onMessage(message))
    .subscribe();
  return () => supabase.removeChannel(channel);
}
