<script setup>
const themes = [
  {
    name: 'light',
    icon: 'bx-sun',
  },
  {
    name: 'dark',
    icon: 'bx-moon',
  },
  {
    name: 'system',
    icon: 'bx-desktop',
  },
]
</script>

<template>
  <ThemeSwitcher :themes="themes" />
</template>
