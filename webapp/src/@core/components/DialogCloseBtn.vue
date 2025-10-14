<script setup>
const props = defineProps({
  icon: {
    type: String,
    required: false,
    default: 'bx-x',
  },
  iconSize: {
    type: String,
    required: false,
    default: '20',
  },
})
</script>

<template>
  <IconBtn
    variant="elevated"
    size="30"
    :ripple="false"
    class="v-dialog-close-btn"
  >
    <VIcon
      :icon="props.icon"
      :size="props.iconSize"
    />
  </IconBtn>
</template>
