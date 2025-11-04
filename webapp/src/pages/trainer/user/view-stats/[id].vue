<template>
  <div>
    <!-- 🧠 Page Header -->
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 font-weight-bold">Statistics for Baby</h2>

      <VBtnToggle
        v-model="timeFrame"
        divided
        color="primary"
        density="comfortable"
        class="ml-auto"
      >
        <VBtn value="daily">Daily</VBtn>
        <VBtn value="weekly">Weekly</VBtn>
      </VBtnToggle>
    </div>

    <VCard>
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
                <p :class="['text-caption mt-1', entriesToday > 0 ? 'text-success' : 'text-error']">
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
            <h3 class="text-h5 font-weight-medium mb-4">
              {{ timeFrame === 'daily' ? 'Daily Summary' : 'Weekly Summary' }}
            </h3>

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
                        Current: {{ formatMetric(metric.value, latestValue(metric.value)) }}
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
              :item-title="item => `${item.title}`"
              item-value="value"
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
                  :class="[ 'd-flex align-center gap-1', percentChange >= 0 ? 'text-success' : 'text-error' ]"
                >
                  <img
                    :src="percentChange >= 0 ? upArrow : downArrow"
                    alt="arrow"
                    style="width: 20px; height: 20px"
                  />
                  <span>{{ Math.abs(percentChange) }}% from previous {{ timeFrame === 'daily' ? 'day' : 'week' }}</span>
                </div>
              </div>

              <div class="text-center">
                <VCircularProgress
                  :model-value="circleValue"
                  color="primary"
                  size="70"
                  width="6"
                />
                <div class="text-caption mt-2">Today: {{ getFormattedValue(selectedMetric.value, activeStats.at(-1)?.[selectedMetric.value]) }}</div>
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
  </div>
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

const stats = ref([])
const weeklyStats = ref([
  { day: 1, totalFeeds: 4, totalUrineCount: 2, totalStoolCount: 1, totalSleepDuration: '9:30', totalPlayDuration: '1:00', monInterval: '20:00', averagePlayDuration: '0:50', averageLapseDuration: '1:30', averageMilkIntake: 60 },
  { day: 2, totalFeeds: 5, totalUrineCount: 3, totalStoolCount: 2, totalSleepDuration: '10:00', totalPlayDuration: '1:10', monInterval: '25:00', averagePlayDuration: '0:55', averageLapseDuration: '1:20', averageMilkIntake: 65 },
  { day: 3, totalFeeds: 6, totalUrineCount: 3, totalStoolCount: 1, totalSleepDuration: '8:45', totalPlayDuration: '1:15', monInterval: '23:00', averagePlayDuration: '0:52', averageLapseDuration: '1:15', averageMilkIntake: 68 },
  { day: 4, totalFeeds: 4, totalUrineCount: 2, totalStoolCount: 1, totalSleepDuration: '9:50', totalPlayDuration: '1:05', monInterval: '22:00', averagePlayDuration: '0:54', averageLapseDuration: '1:18', averageMilkIntake: 63 },
])

const chartReady = ref(false)
const selectedMetric = ref('totalFeeds')
const activeTab = ref('summary')
const timeFrame = ref('daily')
const currentCycle = ref(0)
const entriesToday = ref(0)

// ==================== JOURNAL ENTRY FETCH ==================== //
async function fetchJournalEntries() {
  try {
    const res = await $api(`/journalEntries/${babyId}`, { method: 'GET' })
    const entries = res || []
    currentCycle.value = Math.max(...entries.map(e => e.cycleNo || 0))

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
  { title: 'Total Urine Count', value: 'totalUrineCount' },
  { title: 'Total Stool Count', value: 'totalStoolCount' },
  { title: 'Cycles Beyond 3 hours', value: 'totalCyclesBeyond3Hrs' },
  { title: 'Total Sleep Duration', value: 'totalSleepDuration' },
  { title: 'Total Play Duration', value: 'totalPlayDuration' },
  { title: 'MON Interval', value: 'monInterval' },
  { title: 'Avg Play Duration Per Entry', value: 'averagePlayDuration' },
  { title: 'Lapse Duration', value: 'averageLapseDuration' },
  { title: 'Avg Milk Intake Per Entry', value: 'averageMilkIntake' },
]

const activeStats = computed(() => {
  return timeFrame.value === 'daily' ? stats.value : weeklyStats.value
})

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

// ✅ NEW: Format value consistently (used for today, avg, etc.)
function formatMetric(metric, value) {
  if (isDurationField(metric)) {
    const totalMin = parseDuration(value)
    const h = Math.floor(totalMin / 60)
    const m = Math.round(totalMin % 60)
    return `${h}h ${m}m`
  }
  return value ?? 0
}

function getFormattedValue(metric, rawValue) {
  return formatMetric(metric, rawValue)
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
  if (!t) return 'normal'
  const val = isDurationField(metric) ? parseDuration(value) : Number(value)
  if (val <= t.warning) return 'warning'
  if (val <= t.watch) return 'watch'
  return 'normal'
}

function getStatusLabel(metric) {
  const latest = activeStats.value.at(-1)?.[metric]
  const level = getStatus(metric, latest)
  if (level === 'warning') return 'WARNING'
  if (level === 'watch') return 'WATCH'
  return 'NORMAL'
}

function getStatusColor(metric) {
  const latest = activeStats.value.at(-1)?.[metric]
  const level = getStatus(metric, latest)
  if (level === 'warning') return 'error'
  if (level === 'watch') return 'warning'
  return 'success'
}

function latestValue(metric) {
  return activeStats.value.at(-1)?.[metric] ?? 0
}

function getAverage(metric) {
  const total = activeStats.value.reduce((acc, s) => {
    const val = isDurationField(metric) ? parseDuration(s[metric]) : Number(s[metric])
    return acc + val
  }, 0)
  const avg = total / (activeStats.value.length || 1)
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
      data: activeStats.value.map(s =>
        isDurationField(metric) ? parseDuration(s[metric]) : Number(s[metric])
      ),
    },
  ]
})

const chartOptions = computed(() => ({
  chart: { id: 'baby-stats-chart', toolbar: { show: false }, foreColor: '#ccc' },
  stroke: { curve: 'smooth', width: 3 },
  xaxis: {
    categories: activeStats.value.map((s, i) =>
      timeFrame.value === 'weekly' ? `Week ${i + 1}` : `Day ${s.day}`
    ),
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

const todayDisplay = computed(() =>
  getFormattedValue(selectedMetric.value, activeStats.value.at(-1)?.[selectedMetric.value])
)

const totalDisplay = computed(() => {
  const metric = selectedMetric.value
  const total = activeStats.value.reduce((acc, s) => {
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
  const today = activeStats.value.at(-1)?.[metric]
  const prev = activeStats.value.at(-2)?.[metric]
  const t = isDurationField(metric) ? parseDuration(today) : Number(today)
  const p = isDurationField(metric) ? parseDuration(prev) : Number(prev)
  if (isNaN(t) || isNaN(p) || p === 0) return null
  return parseFloat(((t - p) / p * 100).toFixed(1))
})

const circleValue = computed(() => {
  const today = activeStats.value.at(-1)?.[selectedMetric.value]
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
