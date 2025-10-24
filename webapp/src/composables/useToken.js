import { useStorage } from '@vueuse/core'

export function useToken() {
  const local = useStorage('accessToken', '', localStorage)
  const session = useStorage('accessToken', '', sessionStorage)

  function setToken(value, remember = false) {
    if (remember) {
      local.value = value
      session.value = ''
    } else {
      session.value = value
      local.value = ''
    }
  }

  function getToken() {
    return local.value || session.value
  }

  function clearToken() {
    local.value = ''
    session.value = ''
  }

  return {
    setToken,
    getToken,
    clearToken,
  }
}
