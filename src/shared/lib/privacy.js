export function containsPrivateContact(value) {
  return /\+?\d[\d\s().-]{7,}\d/.test(value)
    || /(?:^|[^a-z])(calle|cal\.?|avenida|av\.?|jr\.?|jiron|jirón|mz\.?|manzana|lote|lt\.?|dpto|depto|interior|nro\.?|numero|pasaje|psje\.?|carretera|camino\s+real)(?=$|[^a-z])[^.!?\n]{0,120}\d{1,5}/i.test(value)
    || /(?:^|\D)\d{1,5}\s*,\s*(calle|cal\.?|avenida|av\.?|jr\.?|jiron|jirón|pasaje|psje\.?|carretera|camino\s+real)\b/i.test(value);
}

export function containsPrivateContactInFields(first, second) {
  if (containsPrivateContact(first) || containsPrivateContact(second)) return true;
  const street = '(?:calle|cal\\.?|avenida|av\\.?|jr\\.?|jiron|jirón|mz\\.?|manzana|lote|lt\\.?|dpto|depto|interior|nro\\.?|numero|pasaje|psje\\.?|carretera|camino\\s+real)';
  const endsWithStreet = new RegExp(`(?:^|[^a-z])${street}(?=$|[^a-z])[^.!?\\n]{0,80}$`, 'i');
  const startsWithNumber = /^\s*(?:(?:altura|alt\.?|nro\.?|numero|n[°ºo.]|#)\s*)?\d{1,5}(?:\D|$)/i;
  const endsWithNumber = /(?:^|\D)\d{1,5}\s*,?\s*$/;
  const startsWithStreet = new RegExp(`^\\s*${street}\\b`, 'i');
  return (endsWithStreet.test(first) && startsWithNumber.test(second))
    || (endsWithStreet.test(second) && startsWithNumber.test(first))
    || (endsWithNumber.test(first) && startsWithStreet.test(second))
    || (endsWithNumber.test(second) && startsWithStreet.test(first));
}

export function isApproximateArea(value) {
  return value.trim().length >= 2 && value.trim().length <= 80
    && !/[0-9#]/.test(value)
    && !/\b(calle|cal\.?|avenida|av\.?|jr\.?|jiron|jirón|mz\.?|manzana|lote|lt\.?|dpto|depto|departamento|interior|int|piso|nro\.?|numero|pasaje|psje\.?|carretera|camino\s+real)\b/i.test(value);
}
