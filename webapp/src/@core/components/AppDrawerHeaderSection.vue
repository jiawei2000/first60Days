<script setup>
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
})

const emit = defineEmits(['cancel'])
</script>

<template>
  <div class="px-6 py-5 d-flex align-center">
    <h5 class="text-h5">
      {{ props.title }}
    </h5>
    <VSpacer />

    <slot name="beforeClose" />

    <IconBtn @click="$emit('cancel', $event)">
      <VIcon
        icon="bx-x"
        size="24"
      />
    </IconBtn>
  </div>
</template>
