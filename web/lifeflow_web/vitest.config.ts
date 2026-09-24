import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    // Mesmo alias `@/*` do tsconfig, para testes que importam módulos com paths.
    alias: { "@": fileURLToPath(new URL("./", import.meta.url)) },
  },
});
