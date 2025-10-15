<script setup>
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  image: {
    type: String,
    required: true,
  },
  color: {
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

const moreList = [
  {
    title: 'Yesterday',
    value: 'yesterday',
  },
  {
    title: 'Last Week',
    value: 'lastWeek',
  },
  {
    title: 'Last Month',
    value: 'lastMonth',
  },
]
</script>

<template>
  <VCard>
    <VCardText class="d-flex align-center justify-space-between pb-4">
      <VAvatar
        rounded
        variant="text"
        :color="props.color"
        :image="props.image"
        size="40"
      />
      <MoreBtn
        size="small"
        :menu-list="moreList"
      />
    </VCardText>

    <VCardText>
      <p class="mb-0">
        {{ props.title }}
      </p>
      <h4 class="text-h4 text-no-wrap mb-3">
        {{ props.stats }}
      </h4>
      <span
        :class="isPositive ? 'text-success' : 'text-error'"
        class="d-flex align-center gap-1 text-sm font-weight-medium"
      >
        <VIcon
          size="20"
          :icon="isPositive ? 'bx-up-arrow-alt' : 'bx-down-arrow-alt'"
        />
        {{ Math.abs(props.change) }}%
      </span>
    </VCardText>
  </VCard>
</template>
