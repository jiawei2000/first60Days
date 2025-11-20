<script setup>
const bufferValue = ref(20)
const progressValue = ref(10)
const isFallbackState = ref(false)
const interval = ref()
const showProgress = ref(false)

function startBuffer() {
  clearInterval(interval.value)
  interval.value = setInterval(() => {
    if (!isFallbackState.value)
      return

    const progressIncrement = Math.random() * (20 - 8) + 8
    const bufferIncrement = Math.random() * (20 - 10) + 10

    // Cap while loading so it feels fast but never completes fully
    progressValue.value = Math.min(progressValue.value + progressIncrement, 95)
    bufferValue.value = Math.min(bufferValue.value + bufferIncrement, 100)
  }, 250)
}

const fallbackHandle = () => {
  // Already in fallback/loading state: avoid restarting animation
  if (isFallbackState.value)
    return

  showProgress.value = true
  // Jump forward a bit so feedback feels instant
  progressValue.value = Math.max(progressValue.value, 30)
  isFallbackState.value = true
  startBuffer()
}

const resolveHandle = () => {
  // Already resolved/hidden: no-op
  if (!isFallbackState.value && !showProgress.value)
    return

  isFallbackState.value = false
  progressValue.value = 100
  setTimeout(() => {
    clearInterval(interval.value)
    progressValue.value = 0
    bufferValue.value = 20
    showProgress.value = false
  }, 200)
}

defineExpose({
  fallbackHandle,
  resolveHandle,
})
</script>

<template>
  <!-- loading state via #fallback slot -->
  <div
    v-if="showProgress"
    class="position-fixed"
    style="z-index: 9999; inset-block-start: 0; inset-inline: 0 0;"
  >
    <VProgressLinear
      v-model="progressValue"
      :buffer-value="bufferValue"
      color="primary"
      height="2"
      bg-color="background"
    />
  </div>
</template>
