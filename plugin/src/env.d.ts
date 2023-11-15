/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_URL: string
  readonly VITE_API_URL: string
  readonly VITE_DEVNET_URL: string
  readonly VITE_REMOTE_DEVNET_URL: string
  readonly VITE_VERSION: string
  readonly VITE_WALLET_CONNECT_PROJECT_ID: string
  // more env variables...
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
