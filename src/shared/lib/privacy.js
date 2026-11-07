export function containsPrivateContact(value) {
  return /\+?\d[\d\s().-]{7,}\d/.test(value)
    || /\b(calle|avenida|av\.?|jr\.?|jiron|jirón|mz\.?|manzana|lote|lt\.?|dpto|depto|interior|nro\.?|numero)\s+[^,]{0,24}\d/i.test(value);
}
