import { defineConfig } from "vite";
import glsl from "vite-plugin-glsl";
import cesium from "vite-plugin-cesium";

import * as path from "path";

export default defineConfig({
  resolve: {
    extensions: [".js", ".vue", ".json", ".ts"],
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  plugins: [cesium(), glsl()],
});
