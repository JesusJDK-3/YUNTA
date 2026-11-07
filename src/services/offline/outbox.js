const DB_NAME = 'yunta-offline';
const STORE_NAME = 'pending-posts';
const PROFILE_STORE = 'profile-cache';
const DB_VERSION = 2;

function openQueue() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'id' });
      }
      if (!db.objectStoreNames.contains(PROFILE_STORE)) {
        db.createObjectStore(PROFILE_STORE, { keyPath: 'id' });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function runTransaction(storeName, mode, action) {
  const db = await openQueue();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, mode);
    const request = action(transaction.objectStore(storeName));
    transaction.oncomplete = () => {
      db.close();
      resolve(request?.result);
    };
    transaction.onerror = () => { db.close(); reject(transaction.error); };
    transaction.onabort = () => { db.close(); reject(transaction.error); };
  });
}

export function savePendingPost(post) {
  return runTransaction(STORE_NAME, 'readwrite', (store) => store.put({
    ...post,
    state: 'pending',
    queued_at: new Date().toISOString(),
  }));
}

export function listPendingPosts() {
  return runTransaction(STORE_NAME, 'readonly', (store) => store.getAll());
}

export function removePendingPost(id) {
  return runTransaction(STORE_NAME, 'readwrite', (store) => store.delete(id));
}

export function saveProfileCache(profile) {
  const safeProfile = {
    id: 'current', display_name: profile.display_name, area_label: profile.area_label,
    latitude: Number(Number(profile.latitude).toFixed(3)), longitude: Number(Number(profile.longitude).toFixed(3)),
    location_source: profile.location_source,
    tutorial_completed_at: profile.tutorial_completed_at ?? null,
  };
  return runTransaction(PROFILE_STORE, 'readwrite', (store) => store.put(safeProfile));
}

export async function getProfileCache() {
  const profile = await runTransaction(PROFILE_STORE, 'readonly', (store) => store.get('current'));
  if (!profile) return null;
  const { id, ...safeProfile } = profile;
  return safeProfile;
}
