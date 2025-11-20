import { ref } from 'vue'

// Number of in-flight API/router requests
export const activeRequests = ref(0)

// Smoothed flag used by the UI so the bar
// doesn't flicker between back-to-back requests.
export const isUiLoading = ref(false)

let hideTimeout

export const startLoading = () => {
  activeRequests.value += 1

  // First request in a batch – ensure UI is on.
  if (activeRequests.value === 1) {
    if (hideTimeout) {
      clearTimeout(hideTimeout)
      hideTimeout = undefined
    }

    isUiLoading.value = true
  }
}

export const stopLoading = () => {
  if (activeRequests.value > 0)
    activeRequests.value -= 1

  // Only when nothing is in-flight, schedule hide.
  if (activeRequests.value === 0 && !hideTimeout) {
    hideTimeout = setTimeout(() => {
      isUiLoading.value = false
      hideTimeout = undefined
    }, 250) // brief delay to avoid flicker on quick requests
  }
}
