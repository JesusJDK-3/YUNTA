import { Component, type ReactNode } from "react";

interface Props {
  children: ReactNode;
}

interface State {
  message: string | null;
}

/**
 * Si un render se cae, la persona ve una salida en lugar de una pantalla en blanco.
 * El detalle del error queda en la consola para quien desarrolla.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { message: null };

  static getDerivedStateFromError(error: unknown): State {
    console.error(error);
    return { message: "Yunta tuvo un problema al dibujar esta pantalla." };
  }

  render() {
    if (!this.state.message) return this.props.children;
    return (
      <main className="sheet">
        <h1>Yunta</h1>
        <p role="alert">{this.state.message}</p>
        <button type="button" className="btn btn-primary" onClick={() => window.location.assign("/")}>
          Volver a empezar
        </button>
      </main>
    );
  }
}
