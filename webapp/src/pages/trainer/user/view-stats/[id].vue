<template>
  <VCard>
    <!-- 📊 Top Summary Cards -->
    <VCardText>
      <VRow class="mb-2">
        <VCol cols="12" sm="6" md="4">
          <VCard class="pa-4 d-flex align-center" style="background-color: #f6f9f6">
            <VAvatar size="48" class="me-4" color="success" variant="tonal">
              <VImg :src="cycle" width="28" height="28" cover />
            </VAvatar>
            <div>
              <p class="text-caption text-medium-emphasis mb-0">Current Cycle</p>
              <h3 class="text-h5 font-weight-bold mb-0">{{ currentCycle || '-' }}</h3>
              <p class="text-caption text-success mt-1">Updated today</p>
            </div>
          </VCard>
        </VCol>

        <VCol cols="12" sm="6" md="4">
          <VCard class="pa-4 d-flex align-center" style="background-color: #f6f7fb">
            <VAvatar size="48" class="me-4" color="info" variant="tonal">
              <VImg :src="entry" width="28" height="28" cover />
            </VAvatar>
            <div>
              <p class="text-caption text-medium-emphasis mb-0">Entries Today</p>
              <h3 class="text-h5 font-weight-bold mb-0">{{ entriesToday }}</h3>
              <p
                :class="[
                  'text-caption mt-1',
                  entriesToday > 0 ? 'text-success' : 'text-error',
                ]"
              >
                {{ entriesToday > 0 ? 'Good activity' : 'No entries yet' }}
              </p>
            </div>
          </VCard>
        </VCol>
      </VRow>
    </VCardText>

    <!-- Tabs -->
    <VTabs v-model="activeTab" background-color="transparent" grow>
      <VTab value="summary">Summary</VTab>
      <VTab value="trends">Trends</VTab>
    </VTabs>

    <VDivider />

    <VWindow v-model="activeTab" class="pa-4">
      <!-- 🟩 SUMMARY TAB -->
      <VWindowItem value="summary">
        <VCardText>
          <h3 class="text-h5 font-weight-medium mb-4">Baby Summary</h3>

          <VRow>
            <VCol
              v-for="metric in metricOptions"
              :key="metric.value"
              cols="12"
              sm="6"
              md="4"
            >
              <VCard class="pa-4" elevation="1">
                <div class="d-flex align-center justify-space-between">
                  <div>
                    <p class="text-subtitle-1 font-weight-medium mb-1">
                      {{ metric.title }}
                    </p>
                    <p class="text-body-2 text-medium-emphasis mb-0">
                      Current: {{ latestValue(metric.value) }}
                    </p>
                    <p class="text-body-2 text-medium-emphasis mb-0">
                      Avg: {{ getAverage(metric.value) }}
                    </p>
                  </div>

                  <VChip
                    :color="getStatusColor(metric.value)"
                    text-color="white"
                    label
                    size="small"
                  >
                    {{ getStatusLabel(metric.value) }}
                  </VChip>
                </div>
              </VCard>
            </VCol>
          </VRow>
        </VCardText>
      </VWindowItem>

      <!-- 📈 TRENDS TAB -->
      <VWindowItem value="trends">
        <VCardText>
          <VSelect
            v-model="selectedMetric"
            :items="metricOptions"
            label="Select Metric"
            density="compact"
            hide-details
            variant="outlined"
            class="mb-4"
          />

          <div class="d-flex align-center justify-space-between mb-6">
            <div>
              <p class="text-body-1 mb-1">{{ currentLabel }}</p>
              <h2 class="text-h4 font-weight-bold">{{ totalDisplay }}</h2>
              <div
                v-if="percentChange !== null"
                :class="[
                  'd-flex align-center gap-1',
                  percentChange >= 0 ? 'text-success' : 'text-error',
                ]"
              >
                <img
                  :src="percentChange >= 0 ? upArrow : downArrow"
                  alt="arrow"
                  style="width: 20px; height: 20px"
                />
                <span>{{ Math.abs(percentChange) }}% from previous day</span>
              </div>
            </div>

            <div class="text-center">
              <VCircularProgress
                :model-value="circleValue"
                color="primary"
                size="70"
                width="6"
              />
              <div class="text-caption mt-2">Today: {{ todayDisplay }}</div>
              <div class="text-caption text-medium-emphasis">
                Avg: {{ averageDisplay }}
              </div>
            </div>
          </div>

          <ApexChart
            v-if="chartReady"
            type="line"
            height="250"
            :options="chartOptions"
            :series="chartSeries"
          />
        </VCardText>
      </VWindowItem>
    </VWindow>
  </VCard>
</template>

<script setup lang="js">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import VueApexCharts from 'vue3-apexcharts'
import upArrow from '@/assets/images/cards/up.png'
import downArrow from '@/assets/images/cards/down.png'
import cycle from '@/assets/images/cards/cycle.png'
import entry from '@/assets/images/cards/entry.png'

const ApexChart = VueApexCharts
const route = useRoute()
const babyId = route.params.id

// API data
const stats = ref([])
const chartReady = ref(false)
const selectedMetric = ref('totalFeeds')
const activeTab = ref('summary')

// New summary card values
const currentCycle = ref(0)
const entriesToday = ref(0)

// ==================== JOURNAL ENTRY FETCH ==================== //
async function fetchJournalEntries() {
  try {
    const res = await $api(`/journalEntries/${babyId}`, { method: 'GET' })
    const entries = res || []

    // Current Cycle = highest cycleNo
    currentCycle.value = Math.max(...entries.map(e => e.cycleNo || 0))

    // Entries Today = entries whose awakeTime date == today
    const today = new Date().toISOString().split('T')[0]
    entriesToday.value = entries.filter(e => {
      const awakeDate = new Date(e.awakeTime._seconds * 1000)
        .toISOString()
        .split('T')[0]
      return awakeDate === today
    }).length
  } catch (err) {
    console.error('Failed to fetch journal entries:', err)
  }
}

// ==================== METRIC CONFIG ==================== //
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

function parseDuration(str) {
  if (!str || typeof str !== 'string') return 0
  const [h, m] = str.split(':').map(Number)
  return h * 60 + m
}

function isDurationField(metric) {
  return [
    'totalSleepDuration',
    'totalPlayDuration',
    'monInterval',
    'averagePlayDuration',
    'averageLapseDuration',
  ].includes(metric)
}

const thresholds = {
  totalFeeds: { warning: 3, watch: 5 },
  totalUrineCount: { warning: 2, watch: 4 },
  totalStoolCount: { warning: 1, watch: 2 },
  totalSleepDuration: { warning: 600, watch: 720 },
  totalPlayDuration: { warning: 30, watch: 60 },
  monInterval: { warning: 0, watch: 30 },
  averageMilkIntake: { warning: 30, watch: 45 },
}

function getStatus(metric, value) {
  const t = thresholds[metric]
  if (!t) return 'safe'
  const val = isDurationField(metric) ? parseDuration(value) : Number(value)
  if (val <= t.warning) return 'warning'
  if (val <= t.watch) return 'watch'
  return 'safe'
}

function getStatusLabel(metric) {
  const latest = stats.value.at(-1)?.[metric]
  const level = getStatus(metric, latest)
  if (level === 'warning') return 'WARNING'
  if (level === 'watch') return 'WATCH'
  return 'SAFE'
}

function getStatusColor(metric) {
  const latest = stats.value.at(-1)?.[metric]
  const level = getStatus(metric, latest)
  if (level === 'warning') return 'error'
  if (level === 'watch') return 'warning'
  return 'success'
}

function latestValue(metric) {
  const latest = stats.value.at(-1)?.[metric]
  return isDurationField(metric) ? latest || '0:00' : latest ?? 0
}

function getAverage(metric) {
  const total = stats.value.reduce((acc, s) => {
    const val = isDurationField(metric) ? parseDuration(s[metric]) : Number(s[metric])
    return acc + val
  }, 0)
  const avg = total / (stats.value.length || 1)
  if (isDurationField(metric)) {
    const h = Math.floor(avg / 60)
    const m = Math.round(avg % 60)
    return `${h}h ${m}m`
  }
  return avg.toFixed(1)
}

// ==================== CHART ==================== //
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
  chart: { id: 'baby-stats-chart', toolbar: { show: false }, foreColor: '#ccc' },
  stroke: { curve: 'smooth', width: 3 },
  xaxis: {
    categories: stats.value.map(s => `Day ${s.day}`),
    labels: { style: { colors: '#ccc', fontSize: '12px' } },
  },
  yaxis: {
    labels: { style: { colors: '#ccc', fontSize: '12px' } },
    min: 0,
    tickAmount: 4,
  },
  colors: ['#7367F0'],
}))

const currentLabel = computed(() =>
  metricOptions.find(opt => opt.value === selectedMetric.value)?.title || selectedMetric.value
)

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
  return total
})

const averageDisplay = computed(() => getAverage(selectedMetric.value))

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

// ==================== FETCH DATA ==================== //
onMounted(async () => {
  try {
    const res = await $api(`/statistics/daily/baby/${babyId}`, { method: 'GET' })
    stats.value = res.data?.statistics || []
    chartReady.value = true
  } catch (e) {
    console.error('Failed to load stats:', e)
  }

  await fetchJournalEntries()
})
</script>
