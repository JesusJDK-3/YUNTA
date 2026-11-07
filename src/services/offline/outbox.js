const DB_NAME = 'yunta-offline';
const STORE_NAME = 'pending-posts';
const DB_VERSION = 1;

function openQueue() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'id' });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function runTransaction(mode, action) {
  const db = await openQueue();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, mode);
    const request = action(transaction.objectStore(STORE_NAME));
    transaction.oncomplete = () => {
      db.close();
      resolve(request?.result);
    };
    transaction.onerror = () => { db.close(); reject(transaction.error); };
    transaction.onabort = () => { db.close(); reject(transaction.error); };
  });
}

export function savePendingPost(post) {
  return runTransaction('readwrite', (store) => store.put({
    ...post,
    state: 'pending',
    queued_at: new Date().toISOString(),
  }));
}

export function listPendingPosts() {
  return runTransaction('readonly', (store) => store.getAll());
}

export function removePendingPost(id) {
  return runTransaction('readwrite', (store) => store.delete(id));
}
