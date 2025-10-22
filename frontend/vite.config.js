import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    port: 3000
  },
  define: {
    'import.meta.env.VITE_API_URL': JSON.stringify(process.env.VITE_API_URL || 'http://localhost:8000')
  }
});
