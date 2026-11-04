import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        terms: resolve(__dirname, 'terms.html'),
        eula: resolve(__dirname, 'eula.html'),
        features: resolve(__dirname, 'features.html'),
        library: resolve(__dirname, 'library.html')
      }
    }
  }
});
