import { useCallback, useEffect, useRef, useState } from "react";
import { createYuntaApi, readSupabaseConfig, type YuntaApi } from "./data";
import { asYuntaError } from "./domain/errors";
import type { Session } from "./domain/types";
import { usePlace } from "./lib/place";
import { DetailScreen } from "./screens/DetailScreen";
import { Tutorial, tutorialPending } from "./components/Tutorial";
import { EnterScreen } from "./screens/EnterScreen";
import { WallScreen } from "./screens/WallScreen";

/**
 * Tres rutas y nada más: entrar, el muro y el detalle.
 * El historial del navegador permite volver sin una librería de rutas.
 */
export function App() {
  const configRef = useRef(readSupabaseConfig());
  const apiRef = useRef<YuntaApi | null>(null);
  if (configRef.current && !apiRef.current) {
    apiRef.current = createYuntaApi(configRef.current.url, configRef.current.key);
  }
  const api = apiRef.current;

  const [session, setSession] = useState<Session | null>(null);
  const [pendingEmail, setPendingEmail] = useState<string | null>(null);
  const [booting, setBooting] = useState(true);
  const [notice, setNotice] = useState<string | null>(null);
  const [path, setPath] = useState(() => window.location.pathname);
  const [showTutorial, setShowTutorial] = useState(false);
  const place = usePlace();

  const go = useCallback((to: string) => {
    window.history.pushState({}, "", to);
    setPath(to);
  }, []);

  const refresh = useCallback(async () => {
    if (!api) {
      setBooting(false);
      return;
    }
    try {
      const [nextSession, email, note, sent] = await Promise.all([
        api.currentSession(),
        api.pendingEmail(),
        api.takeNotice(),
        api.flushPublishes(),
      ]);
      setSession(nextSession);
      if (nextSession && tutorialPending()) setShowTutorial(true);
      setPendingEmail(email);
      if (note) setNotice(note);
      if (sent > 0) setNotice(`Se enviaron ${sent} avisos que estaban pendientes.`);
    } catch (error) {
      setNotice(asYuntaError(error).message);
    } finally {
      setBooting(false);
    }
  }, [api]);

  useEffect(() => {
    if (!api) return;
    void refresh();
    const unwatch = api.watchSession(() => {
      void refresh();
    });
    const onPop = () => setPath(window.location.pathname);
    const onOnline = () => {
      void refresh();
    };
    window.addEventListener("popstate", onPop);
    window.addEventListener("online", onOnline);
    return () => {
      unwatch();
      window.removeEventListener("popstate", onPop);
      window.removeEventListener("online", onOnline);
    };
  }, [api, refresh]);

  if (!api) return <SetupScreen />;

  if (booting) {
    return (
      <main className="sheet">
        <p>Abriendo Yunta…</p>
      </main>
    );
  }

  if (!session) {
    return (
      <EnterScreen
        api={api}
        pendingEmail={pendingEmail}
        notice={notice}
        onReady={(next) => {
          setSession(next);
          setShowTutorial(tutorialPending());
          setNotice(null);
          go("/muro");
        }}
      />
    );
  }

  const aviso = /^\/aviso\/([0-9a-f-]{36})$/i.exec(path);
  if (aviso) {
    return (
      <DetailScreen
        api={api}
        id={aviso[1] ?? ""}
        userId={session.userId}
        onBack={() => go("/muro")}
        onOpen={(id) => go(`/aviso/${id}`)}
      />
    );
  }

  return (
    <>
    {showTutorial ? <Tutorial onDone={() => setShowTutorial(false)} /> : null}
    <WallScreen
      api={api}
      session={session}
      notice={notice}
      clearNotice={() => setNotice(null)}
      place={place}
      onOpen={(id) => go(`/aviso/${id}`)}
      onLeave={() => {
        void api.signOut().then(() => {
          setSession(null);
          go("/");
        });
      }}
    />
    </>
  );
}

function SetupScreen() {
  return (
    <main className="sheet">
      <h1>Falta conectar Yunta</h1>
      <p>
        En el servidor hacen falta <code>VITE_SUPABASE_URL</code> y <code>VITE_SUPABASE_ANON_KEY</code>.
        Usa la anon key. La service role no va en la web.
      </p>
    </main>
  );
}
