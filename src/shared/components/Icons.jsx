const paths = {
  home: <><path d="m3 10 9-7 9 7"/><path d="M5 9v11h14V9M9 20v-6h6v6"/></>,
  help: <><circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 0 1 5 0c0 2-2.5 2-2.5 4M12 17h.01"/></>,
  store: <><path d="M4 9h16l-1-5H5L4 9Z"/><path d="M5 9v11h14V9M9 20v-6h6v6M4 9c0 2 3 2 3 0 0 2 4 2 4 0 0 2 4 2 4 0 0 2 5 2 5 0"/></>,
  alert: <><path d="m12 3 9 16H3l9-16Z"/><path d="M12 9v4m0 3h.01"/></>,
  plus: <><path d="M12 5v14M5 12h14"/></>,
  pin: <><path d="M20 10c0 5-8 11-8 11S4 15 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="2.5"/></>,
  person: <><circle cx="12" cy="8" r="3.5"/><path d="M5 21a7 7 0 0 1 14 0"/></>,
  close: <><path d="m6 6 12 12M18 6 6 18"/></>,
  chevron: <path d="m8 10 4 4 4-4"/>,
  message: <><path d="M20 11.5a7.5 7.5 0 0 1-8 7.5 8.6 8.6 0 0 1-3.7-.8L4 20l1.5-3.3A7 7 0 0 1 4 12c0-4.4 3.6-8 8-8s8 3.1 8 7.5Z"/><path d="M8 12h8m-8 3h5"/></>,
  heart: <path d="M20.8 8.8c0 5.2-8.8 10-8.8 10s-8.8-4.8-8.8-10a4.8 4.8 0 0 1 8.8-2.2 4.8 4.8 0 0 1 8.8 2.2Z"/>,
  check: <path d="m5 12 4 4L19 6"/>,
};

export function Icon({ name, size = 20, ...props }) {
  return (
    <svg aria-hidden="true" width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" {...props}>
      {paths[name] ?? paths.help}
    </svg>
  );
}
