import { ofetch } from 'ofetch'
import { startLoading, stopLoading } from '@/utils/loading-indicator'

export const $api = ofetch.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',

  async onRequest({ options }) {
    startLoading()

    const accessToken = useCookie('accessToken').value
    if (accessToken) {
      const existingHeaders = options.headers || {}

      options.headers = {
        ...existingHeaders,
        Authorization: `Bearer ${accessToken}`,
      }
    }
  },

  async onResponse() {
    stopLoading()
  },

  async onRequestError() {
    stopLoading()
  },

  async onResponseError() {
    stopLoading()
  },
})
