import { useCallback, useEffect, useState } from 'react';
import './app.css';
import Onboarding from '../features/auth/Onboarding';
import ProfilePanel from '../features/auth/ProfilePanel';
import Tutorial from '../features/auth/Tutorial';
import { getProfile, saveProfile, subscribeToSession } from '../features/auth/auth';
import CaseView from '../features/coordination/CaseView';
import PostComposer from '../features/posts/PostComposer';
import Wall from '../features/wall/Wall';
import { getProfileCache, listPendingPosts, saveProfileCache } from '../services/offline/outbox';
import { isSupabaseConfigured, supabase } from '../services/supabase/client';
import { loadNearby, loadPost, postAction, syncPendingPosts, createPost } from '../services/yuntaApi';
import { Icon } from '../shared/components/Icons';

export default function App() {
  const [session, setSession] = useState(null);
  const [profile, setProfile] = useState(null);
  const [booting, setBooting] = useState(true);
  const [needsTutorial, setNeedsTutorial] = useState(false);
  const [category, setCategory] = useState('help');
  const [posts, setPosts] = useState([]);
  const [pending, setPending] = useState([]);
  const [detail, setDetail] = useState(null);
  const [composing, setComposing] = useState(false);
  const [profileView, setProfileView] = useState(false);
  const [wallError, setWallError] = useState('');
  const [notice, setNotice] = useState('');
  const [online, setOnline] = useState(navigator.onLine);
  const [installEvent, setInstallEvent] = useState(null);

  useEffect(() => {
    let mounted = true;
    if (!isSupabaseConfigured) { setBooting(false); return undefined; }
    supabase.auth.getSession().then(async ({ data, error }) => {
      if (!mounted) return;
      if (error) { setWallError(error.message); setBooting(false); return; }
      const current = data.session;
      setSession(current);
      if (current) {
        const savedProfile = await getProfile().catch(() => null);
        const cachedProfile = savedProfile ? null : await getProfileCache().catch(() => null);
        const restored = savedProfile ?? cachedProfile;
        if (mounted && restored) {
          setProfile(restored);
          setNeedsTutorial(!restored.tutorial_completed_at);
          if (savedProfile) saveProfileCache(savedProfile).catch(() => {});
        } else if (mounted && !savedProfile) setWallError('No se pudo restaurar el perfil. Conéctate para volver a intentarlo.');
      }
      if (mounted) setBooting(false);
    }).catch((cause) => { if (mounted) { setWallError(cause.message); setBooting(false); } });
    const { data: authState } = subscribeToSession(setSession);
    return () => { mounted = false; authState.subscription.unsubscribe(); };
  }, []);

  useEffect(() => {
    function updateOnline() { setOnline(navigator.onLine); }
    function captureInstall(event) { event.preventDefault(); setInstallEvent(event); }
    window.addEventListener('online', updateOnline);
    window.addEventListener('offline', updateOnline);
    window.addEventListener('beforeinstallprompt', captureInstall);
    return () => {
      window.removeEventListener('online', updateOnline);
      window.removeEventListener('offline', updateOnline);
      window.removeEventListener('beforeinstallprompt', captureInstall);
    };
  }, []);

  const refreshWall = useCallback(async () => {
    if (!profile || !session) return;
    setWallError('');
    const queued = await listPendingPosts().catch(() => []);
    setPending(queued);
    if (!online) { setPosts([]); return; }
    try {
      const items = await loadNearby();
      setPosts(items);
    } catch (cause) { setWallError(cause.message || 'No se pudo cargar el muro.'); }
  }, [online, profile, session]);

  useEffect(() => { refreshWall(); }, [refreshWall]);

  useEffect(() => {
    if (!online || !session) return;
    syncPendingPosts().then(async (count) => {
      if (count) { showNotice(`${count} ${count === 1 ? 'aviso sincronizado' : 'avisos sincronizados'}.`); await refreshWall(); }
    }).catch(() => {});
  }, [online, refreshWall, session]);

  useEffect(() => {
    if (!online || !session) return undefined;
    let active = true;
    Promise.all([getProfile(), getProfileCache()]).then(async ([remote, cached]) => {
      if (!remote) return;
      let fresh = remote;
      if (cached?.tutorial_completed_at && !remote.tutorial_completed_at) {
        await saveProfile(remote, true);
        fresh = { ...remote, tutorial_completed_at: cached.tutorial_completed_at };
      }
      if (active) {
        setProfile(fresh);
        setNeedsTutorial(!fresh.tutorial_completed_at);
        await saveProfileCache(fresh);
      }
    }).catch(() => {});
    return () => { active = false; };
  }, [online, session]);

  function showNotice(message) {
    setNotice(message);
    window.setTimeout(() => setNotice(''), 3500);
  }

  async function openPost(post) {
    if (post.status === 'pending') { showNotice('El aviso aparecerá en el muro cuando vuelva la conexión.'); return; }
    try { setDetail(await loadPost(post.id)); }
    catch (cause) { setWallError(cause.message || 'No se pudo abrir este aviso.'); }
  }

  async function createNewPost(post) {
    const created = await createPost(post);
    setComposing(false);
    if (created.status === 'pending') {
      const queued = await listPendingPosts(); setPending(queued);
      showNotice('Aviso guardado en este dispositivo; se enviará cuando vuelva internet.');
      return;
    }
    await refreshWall();
    setDetail(await loadPost(created.id));
    showNotice('Aviso publicado para los vecinos cercanos.');
  }

  async function runAction(name, args) {
    await postAction(name, args);
    const updated = await loadPost(detail.id);
    setDetail(updated);
    await refreshWall();
    return updated;
  }

  async function install() {
    if (!installEvent) return;
    await installEvent.prompt();
    setInstallEvent(null);
  }

  if (!isSupabaseConfigured) return <ConfigurationNotice />;
  if (booting) return <main className="boot-screen"><img src="/icons/yunta.svg" alt="" /><p>Abriendo Yunta…</p></main>;
  if (!profile) return <Onboarding onComplete={(saved) => {
    setProfile(saved); setWallError(''); setNeedsTutorial(true); saveProfileCache(saved).catch(() => {});
  }} />;

  return (
    <div className="app-shell">
      <header className="app-header">
        <a className="brand-lockup" href="#muro" onClick={(event) => { event.preventDefault(); setDetail(null); setProfileView(false); }}>
          <img src="/icons/yunta.svg" alt="" width="40" height="40" /><span>Yunta</span>
        </a>
        <div className="header-actions">
          <span className={`connection-pill ${online ? 'is-online' : 'is-offline'}`}><i />{online ? 'Conectado' : 'Sin conexión'}</span>
          {installEvent && <button className="text-button install-button" onClick={install}>Instalar app</button>}
          <button className="profile-shortcut" onClick={() => { setDetail(null); setProfileView(true); }} aria-label="Abrir perfil">
            <span className="avatar">{profile.display_name.slice(0, 1).toUpperCase()}</span>
            <span className="profile-name">{profile.display_name}</span>
          </button>
        </div>
      </header>
      <div className="app-layout">
        <aside className="side-rail" aria-label="Navegación">
          <button className={!profileView ? 'rail-item selected' : 'rail-item'} onClick={() => { setProfileView(false); setDetail(null); }}><Icon name="home" /><span>Muro</span></button>
          <button className={profileView ? 'rail-item selected' : 'rail-item'} onClick={() => { setProfileView(true); setDetail(null); }}><Icon name="person" /><span>Mi perfil</span></button>
          <div className="rail-note">A 500 m<br />de tu zona</div>
        </aside>
        <main className="main-content">
          {profileView ? <ProfilePanel profile={profile} online={online} onBack={() => setProfileView(false)}
            onSave={(saved) => { setProfile(saved); saveProfileCache(saved).catch(() => {}); }} onToast={showNotice} />
            : detail ? <CaseView post={detail} userId={session.user.id} onBack={() => setDetail(null)}
              onRefresh={runAction} onToast={showNotice} online={online} />
              : <Wall category={category} onCategory={setCategory} posts={posts} pending={pending}
                error={wallError} onRefresh={refreshWall} onPublish={() => setComposing(true)} onOpen={openPost} />}
        </main>
      </div>
      <nav className="mobile-nav" aria-label="Navegación principal">
        <button className={!profileView ? 'active' : ''} onClick={() => { setProfileView(false); setDetail(null); }}><Icon name="home" /><span>Muro</span></button>
        <button className={profileView ? 'active' : ''} onClick={() => { setProfileView(true); setDetail(null); }}><Icon name="person" /><span>Perfil</span></button>
      </nav>
      {composing && <PostComposer profile={profile} initialCategory={category} onClose={() => setComposing(false)} onSubmit={createNewPost} />}
      {needsTutorial && <Tutorial profile={profile} onDone={(saved) => {
        setProfile(saved); setNeedsTutorial(false); saveProfileCache(saved).catch(() => {});
      }} />}
      {notice && <div className="toast" role="status">{notice}</div>}
    </div>
  );
}

function ConfigurationNotice() {
  return <main className="config-screen"><img src="/icons/yunta.svg" alt="" width="52" height="52" />
    <h1>Yunta está preparando tu barrio.</h1>
    <p>Para activar el muro, configura en el entorno de despliegue <code>VITE_SUPABASE_URL</code> y <code>VITE_SUPABASE_PUBLISHABLE_KEY</code>.</p>
    <p>Cuando la conexión esté lista, podrás registrarte y ver publicaciones cercanas.</p>
  </main>;
}
