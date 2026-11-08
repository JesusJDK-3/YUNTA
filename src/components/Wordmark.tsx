/** La Y del equipo se conserva. No se reemplaza por otro símbolo. */
export function Wordmark({ compact = false }: { compact?: boolean }) {
  const size = compact ? 40 : 56;
  return (
    <span className={compact ? "wordmark compact" : "wordmark"}>
      <img src="/icons/yunta-192.png" width={size} height={size} alt="Logotipo Yunta, letra Y" />
      <span>Yunta</span>
    </span>
  );
}
