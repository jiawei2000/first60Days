<template>
  <VCard>
    <!-- Metric Selector -->
    <VCardText>
      <VSelect
        v-model="selectedMetric"
        :items="metricOptions"
        label="Select Metric"
        density="compact"
        hide-details
        variant="outlined"
      />
    </VCardText>

    <!-- Summary -->
    <VCardText>
      <div class="d-flex align-center justify-space-between">
        <div>
          <p class="text-body-1 mb-1">{{ currentLabel }}</p>
          <h2 class="text-h4 font-weight-bold">{{ totalDisplay }}</h2>
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

        <!-- Circle -->
        <div class="text-center">
          <VCircularProgress
            :model-value="circleValue"
            color="primary"
            size="70"
            width="6"
          />
          <div class="text-caption mt-2">Today: {{ todayDisplay }}</div>
        </div>
      </div>

      <!-- Chart -->
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
const ApexChart = VueApexCharts

const route = useRoute()
const babyId = route.params.id

const stats = ref([])
const chartReady = ref(false)
const selectedMetric = ref('totalFeeds')

const metricOptions = [
  { title: 'Total Feeds', value: 'totalFeeds' },
  { title: 'Urine Count', value: 'totalUrineCount' },
  { title: 'Stool Count', value: 'totalStoolCount' },
  { title: 'Cycles > 3hrs', value: 'totalCyclesBeyond3Hrs' },
  { title: 'Sleep Duration', value: 'totalSleepDuration' },
  { title: 'Play Duration', value: 'totalPlayDuration' },
  { title: 'Monitoring Interval', value: 'monInterval' },
  { title: 'Avg Play Duration', value: 'averagePlayDuration' },
  { title: 'Avg Lapse Duration', value: 'averageLapseDuration' },
  { title: 'Avg Milk Intake', value: 'averageMilkIntake' },
]

/* Convert HH:MM string → total minutes (number) */
function parseDuration(str) {
  if (!str || typeof str !== 'string') return 0
  const [h, m] = str.split(':').map(Number)
  return h * 60 + m
}

/* Detect if a metric is a time string */
function isDurationField(metric) {
  return [
    'totalSleepDuration',
    'totalPlayDuration',
    'monInterval',
    'averagePlayDuration',
    'averageLapseDuration',
  ].includes(metric)
}

const chartSeries = computed(() => {
  const metric = selectedMetric.value
  return [
    {
      name: metric,
      data: stats.value.map(s =>
        isDurationField(metric) ? parseDuration(s[metric]) : Number(s[metric])
      ),
    },
  ]
})

const chartOptions = computed(() => ({
  chart: {
    id: 'baby-stats-chart',
    toolbar: { show: false },
    sparkline: { enabled: false },
    foreColor: '#ccc', 
  },
  stroke: {
    curve: 'smooth',
    width: 3,
  },
  xaxis: {
    categories: stats.value.map(s => `Day ${s.day}`),
    labels: {
      style: {
        colors: '#ccc',
        fontSize: '12px',
      },
    },
    axisTicks: { show: true },
    axisBorder: { show: true },
  },
  yaxis: {
    labels: {
      style: {
        colors: '#ccc',
        fontSize: '12px',
      },
      formatter: val => val,
    },
    min: 0,
    tickAmount: 4,
  },
  tooltip: {
    theme: 'dark', 
    style: {
      fontSize: '13px',
      fontFamily: 'Inter, sans-serif',
      color: '#fff', 
    },
  },
  legend: {
    labels: {
      colors: '#ccc',
    },
  },
  colors: ['#7367F0'],
  fill: {
    type: 'gradient',
    gradient: {
      shade: 'dark',
      type: 'vertical',
      gradientToColors: ['#9e95f5'],
      stops: [0, 100],
    },
  },
}))

const currentLabel = computed(() => {
  return metricOptions.find(opt => opt.value === selectedMetric.value)?.title || selectedMetric.value
})

const todayDisplay = computed(() => {
  const latest = stats.value.at(-1)?.[selectedMetric.value]
  if (isDurationField(selectedMetric.value)) return latest || '0:00'
  return latest ?? 0
})

const totalDisplay = computed(() => {
  const metric = selectedMetric.value
  const total = stats.value.reduce((acc, s) => {
    const val = s[metric]
    if (isDurationField(metric)) return acc + parseDuration(val)
    return acc + Number(val)
  }, 0)

  if (isDurationField(metric)) {
    const h = Math.floor(total / 60)
    const m = total % 60
    return `${h}h ${m}m`
  }
  if (metric === 'averageMilkIntake') return `${total.toFixed(1)} ml`
  return total
})

const percentChange = computed(() => {
  const metric = selectedMetric.value
  const today = stats.value.at(-1)?.[metric]
  const prev = stats.value.at(-2)?.[metric]

  const t = isDurationField(metric) ? parseDuration(today) : Number(today)
  const p = isDurationField(metric) ? parseDuration(prev) : Number(prev)

  if (isNaN(t) || isNaN(p) || p === 0) return null
  return parseFloat(((t - p) / p * 100).toFixed(1))
})

const circleValue = computed(() => {
  const today = stats.value.at(-1)?.[selectedMetric.value]
  const val = isDurationField(selectedMetric.value) ? parseDuration(today) : Number(today)
  return Math.min(val * 10, 100)
})

onMounted(async () => {
  try {
    const res = await $api(`/statistics/daily/baby/${babyId}`, { method: 'GET' })
    stats.value = res.data?.statistics || []
    chartReady.value = true
  } catch (e) {
    console.error('Failed to load stats:', e)
  }
})
</script>
