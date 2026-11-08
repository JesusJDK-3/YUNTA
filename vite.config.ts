import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

// Un solo config para la app y para las pruebas del modelo.
// Las pruebas corren en Node: no necesitan el DOM ni la red.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
  },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
