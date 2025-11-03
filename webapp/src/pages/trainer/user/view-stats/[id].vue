<template>
  <VCard>
    <!-- Tabs -->
    <VTabs v-model="tab" grow>
      <VTab>Feeds</VTab>
    </VTabs>

    <VCardText>
      <div class="d-flex align-center justify-space-between">
        <!-- Total Feeds -->
        <div>
          <p class="text-body-1 mb-1">Total Feeds</p>
          <h2 class="text-h4 font-weight-bold">{{ totalFeeds }} feeds</h2>
          <div
            v-if="percentChange !== null"
            :class="percentChange >= 0 ? 'text-success' : 'text-error'"
          >
            <VIcon size="small">
              {{ percentChange >= 0 ? 'mdi-arrow-up' : 'mdi-arrow-down' }}
            </VIcon>
            {{ Math.abs(percentChange) }}% from previous day
          </div>
        </div>

        <!-- Feed Circle Summary -->
        <div class="text-center">
          <VCircularProgress
            :model-value="circleValue"
            color="primary"
            size="70"
            width="6"
          />
          <div class="text-caption mt-2">Today: {{ todayFeeds }} feeds</div>
        </div>
      </div>

      <!-- Line Chart -->
      <ApexChart
        v-if="chartReady"
        type="line"
        height="220"
        :options="chartOptions"
        :series="chartSeries"
        class="mt-6"
      />
    </VCardText>
  </VCard>
</template>

<script setup lang="js">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import VueApexCharts from 'vue3-apexcharts'

/* ✅ Register ApexCharts Locally */
const ApexChart = VueApexCharts

const tab = ref(0)
const route = useRoute()
const babyId = route.params.id

const stats = ref([])
const todayFeeds = ref(0)
const totalFeeds = ref(0)
const percentChange = ref(null)
const chartReady = ref(false)

/* ✅ Circle Progress Value */
const circleValue = computed(() => {
  return todayFeeds.value > 0 ? Math.min(todayFeeds.value * 10, 100) : 0
})

/* ✅ Chart Options */
const chartOptions = computed(() => ({
  chart: {
    id: 'feeds-chart',
    toolbar: { show: false },
    sparkline: { enabled: false }, // ❗ Disable sparkline to show full axes
  },
  stroke: {
    curve: 'smooth',
    width: 3,
  },
  xaxis: {
    categories: stats.value.map(s => `Day ${s.day}`),
    labels: {
      show: true,
      style: {
        colors: '#888',
        fontSize: '12px',
      },
    },
    axisTicks: {
      show: true,
    },
    axisBorder: {
      show: true,
    },
  },
  yaxis: {
    labels: {
      show: true,
      style: {
        colors: '#888',
        fontSize: '12px',
      },
      formatter: val => `${val}`,
    },
    min: 0,
    tickAmount: 4,
  },
  colors: ['#7367F0'],
  fill: {
    type: 'gradient',
    gradient: {
      shade: 'light',
      type: 'vertical',
      gradientToColors: ['#9e95f5'],
      stops: [0, 100],
    },
  },
  tooltip: {
    y: {
      formatter: val => `${val} feeds`,
    },
  },
}))


/* ✅ Chart Data */
const chartSeries = computed(() => [
  {
    name: 'Feeds',
    data: stats.value.map(s => s.totalFeeds),
  },
])

/* ✅ Fetch Baby Statistics */
onMounted(async () => {
  try {
    const res = await $api(`/statistics/daily/baby/${babyId}`, {
      method: 'GET',
    })

    const data = res.data?.statistics ?? []

    stats.value = data.map(item => ({
      day: item.day,
      totalFeeds: item.totalFeeds,
    }))

    const todayStat = stats.value.at(-1)
    const prevStat = stats.value.at(-2)

    todayFeeds.value = todayStat?.totalFeeds || 0
    totalFeeds.value = stats.value.reduce((acc, s) => acc + s.totalFeeds, 0)

    if (prevStat) {
      const diff = todayFeeds.value - prevStat.totalFeeds
      percentChange.value = parseFloat(((diff / prevStat.totalFeeds) * 100).toFixed(1))
    } else {
      percentChange.value = null
    }

    chartReady.value = true
  } catch (e) {
    console.error('Failed to load stats:', e)
  }
})
</script>
