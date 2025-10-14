<script setup>
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    required: true,
  },
  color: {
    type: String,
    required: false,
    default: 'primary',
  },
  icon: {
    type: String,
    required: true,
  },
  stats: {
    type: String,
    required: true,
  },
  change: {
    type: Number,
    required: true,
  },
})

const isPositive = controlledComputed(() => props.change, () => Math.sign(props.change) === 1)
</script>

<template>
  <VCard>
    <VCardText class="d-flex justify-space-between align-start">
      <div class="d-flex flex-column gap-y-1">
        <div class="text-high-emphasis">
          {{ props.title }}
        </div>
        <div class="d-flex align-center flex-wrap gap-2">
          <h4 class="text-h4">
            {{ props.stats }}
          </h4>
          <div
            v-if="props.change"
            :class="`${isPositive ? 'text-success' : 'text-error'}`"
            class="text-base"
          >
            ({{ (isPositive ? '+' : '-') + Math.abs(props.change) }}%)
          </div>
        </div>
        <span class="text-base">{{ props.subtitle }}</span>
      </div>

      <VAvatar
        size="40"
        rounded
        :color="props.color"
        variant="tonal"
      >
        <VIcon
          :icon="props.icon"
          size="24"
        />
      </VAvatar>
    </VCardText>
  </VCard>
</template>
