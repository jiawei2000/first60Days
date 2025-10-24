import { useStorage } from '@vueuse/core'

export function useToken() {
  function setToken(value, remember = false) {
    if (remember) {
      localStorage.setItem('accessToken', value)
      sessionStorage.removeItem('accessToken')
    } else {
      sessionStorage.setItem('accessToken', value)
      localStorage.removeItem('accessToken')
    }
  }

  function getToken() {
    return localStorage.getItem('accessToken') || sessionStorage.getItem('accessToken')
  }

  function clearToken() {
    localStorage.removeItem('accessToken')
    sessionStorage.removeItem('accessToken')
  }

  return {
    setToken,
    getToken,
    clearToken,
  }
}

