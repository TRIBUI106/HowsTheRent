import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig(({ command }) => {
  const buildId = command === 'build'
    ? `${process.env.VERCEL_GIT_COMMIT_SHA ?? process.env.npm_package_version ?? 'dev'}-${Date.now()}`
    : process.env.npm_package_version ?? 'dev'

  return {
  plugins: [react(), tailwindcss()],
  define: {
    __HTR_BUILD_ID__: JSON.stringify(buildId),
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  }
})
