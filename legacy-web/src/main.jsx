import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './app/App.jsx';
import '@fontsource-variable/inter';
import './styles/global.css';

const rootElement = document.getElementById('root');

if (!rootElement) {
  throw new Error('No se encontró el elemento raíz de Yunta.');
}

createRoot(rootElement).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
