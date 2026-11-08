import { useState } from 'react';
import { saveProfile } from './auth';
import { Icon } from '../../shared/components/Icons';

const lessons = [
  { icon: 'plus', title: 'Publica lo que necesitas', copy: 'Pide una mano, ofrece un recurso o comparte un servicio con los vecinos a menos de 500 metros.' },
  { icon: 'message', title: 'Coordina dentro del aviso', copy: 'En un caso individual, quien publicó elige a una persona. En grupo, los participantes comparten el mismo chat.' },
  { icon: 'pin', title: 'Cuida tu dirección', copy: 'El muro solo muestra tu barrio y la distancia aproximada. Comparte la dirección exacta solo durante la coordinación.' },
];

export default function Tutorial({ profile, onDone }) {
  const [step, setStep] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function finish() {
    setBusy(true);
    try {
      if (navigator.onLine) await saveProfile(profile, true);
      onDone({ ...profile, tutorial_completed_at: new Date().toISOString() });
    }
    catch (cause) { setError(cause.message || 'No se pudo guardar el tutorial.'); }
    finally { setBusy(false); }
  }

  const lesson = lessons[step];
  return (
    <div className="tutorial-backdrop">
      <section className="tutorial-card" aria-labelledby="tutorial-title">
        <div className="tutorial-mark"><Icon name={lesson.icon} size={30} /></div>
        <span className="tutorial-count">{step + 1} de {lessons.length}</span>
        <h2 id="tutorial-title">{lesson.title}</h2><p>{lesson.copy}</p>
        <div className="tutorial-progress" aria-label={`Paso ${step + 1} de ${lessons.length}`}>
          {lessons.map((item, index) => <span key={item.title} className={index === step ? 'current' : ''} />)}
        </div>
        {error && <p className="form-error" role="alert">{error}</p>}
        <button className="button button-primary button-wide" onClick={step < lessons.length - 1 ? () => setStep(step + 1) : finish} disabled={busy}>
          {busy ? 'Guardando…' : step < lessons.length - 1 ? 'Siguiente' : 'Ir al muro'}
        </button>
        {step < lessons.length - 1 && <button className="text-button tutorial-skip" onClick={finish} disabled={busy}>Saltar tutorial</button>}
      </section>
    </div>
  );
}
