import { useState } from "react";

const STEPS = [
  {
    title: "Publica en tres toques",
    copy: "Un favor, un oficio o una emergencia. El oficio queda en el directorio. El favor y la emergencia son un caso, con inicio y cierre.",
  },
  {
    title: "Coordina según el caso",
    copy: "Entre dos, se acepta a una persona y el chat es de ustedes. En una cuadra, el grupo comparte el mismo chat.",
  },
  {
    title: "La casa no sale en el muro",
    copy: "Se ve la zona y una distancia redondeada. El celular y la dirección se escriben solo dentro del chat.",
  },
];

const STORAGE_KEY = "yunta.tutorial.v1";

export function tutorialPending(): boolean {
  try {
    return localStorage.getItem(STORAGE_KEY) !== "done";
  } catch {
    return false;
  }
}

export function Tutorial({ onDone }: { onDone: () => void }) {
  const [step, setStep] = useState(0);
  const lesson = STEPS[step] ?? STEPS[0];

  function finish() {
    try {
      localStorage.setItem(STORAGE_KEY, "done");
    } catch {
      // Si el navegador bloquea el almacenamiento, el tutorial no debe atrapar a la persona.
    }
    onDone();
  }

  return (
    <div className="tutorial-backdrop">
      <section className="tutorial-card" aria-labelledby="tutorial-title">
        <p className="muted">
          {step + 1} de {STEPS.length}
        </p>
        <h2 id="tutorial-title">{lesson.title}</h2>
        <p>{lesson.copy}</p>
        <div className="row">
          {step < STEPS.length - 1 ? (
            <button type="button" className="btn btn-primary" onClick={() => setStep((value) => value + 1)}>
              Siguiente
            </button>
          ) : (
            <button type="button" className="btn btn-primary" onClick={finish}>
              Ir al muro
            </button>
          )}
          {step < STEPS.length - 1 ? (
            <button type="button" className="btn btn-ghost" onClick={finish}>
              Saltar
            </button>
          ) : null}
        </div>
      </section>
    </div>
  );
}
