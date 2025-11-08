<template>
  <div>
    <!-- 🧠 Page Header -->
    <div class="d-flex align-center justify-space-between mb-4">
      <h2 class="text-h4 font-weight-bold">Statistics for {{ babyName }}</h2>

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
            <VCard
              class="pa-4 d-flex align-center"
              :class="$vuetify.theme.dark ? 'bg-surface' : 'bg-grey-lighten-5'"
            >
              <VAvatar size="48" class="me-4" color="success" variant="tonal">
                <VImg :src="baby" alt="icon" width="28" height="28" />
              </VAvatar>
              <div>
                <p class="text-caption text-medium-emphasis mb-0">Age</p>
                <h3 class="text-h5 font-weight-bold mb-0">{{ babyAgeWeeks }} weeks</h3>
                <p class="text-caption text-success mt-1">Updated today</p>
              </div>
            </VCard>
          </VCol>

          <VCol cols="12" sm="6" md="4">
            <VCard
              class="pa-4 d-flex align-center"
              :class="$vuetify.theme.dark ? 'bg-surface' : 'bg-grey-lighten-4'"
            >
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
  <!-- 🧭 Shared Date Picker (Top for both Summary & Trends) -->
  <div class="d-flex align-center justify-end mb-2" style="position: relative; z-index: 10;">
    <VMenu
      v-model="dateMenu"
      transition="scale-transition"
      location="bottom end"
      offset-y
      max-width="290"
      min-width="auto"
    >
      <template #activator="{ props }">
        <VBtn
          v-bind="props"
          variant="flat"
          color="primary"
          size="small"
          rounded="lg"
          elevation="1"
        >
          {{ selectedDate ? selectedDate.toISOString().split('T')[0] : 'Select date' }}
        </VBtn>
      </template>

      <VDatePicker
        v-model="selectedDate"
        color="primary"
        :max="new Date()"
        @update:model-value="() => {
          updateStatsForSelectedDate()
          dateMenu.value = false
        }"
      />
    </VMenu>
  </div>

  <!-- 🟩 SUMMARY TAB -->
  <VWindowItem value="summary">
    <VCardText>
      <h3 class="text-h5 font-weight-medium mb-4">
        {{ timeFrame === 'daily' ? 'Daily Summary' : 'Weekly Summary' }}
      </h3>

      <p v-if="timeFrame === 'weekly' && currentWeekLabel" class="text-caption text-medium-emphasis mb-4">
        Showing week: <strong>{{ currentWeekLabel }}</strong>
      </p>

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
                  Average To Date: {{ getAverage(metric.value) }}
                </p>
              </div>

              <VChip
  :color="getThresholdStatus(metric.value).color"
  text-color="white"
  label
  size="small"
>
  {{ getThresholdStatus(metric.value).label }}
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
      <p class="text-caption text-medium-emphasis text-end mb-4">
        Showing last 7 days up to
        <strong>{{ selectedDate ? selectedDate.toISOString().split('T')[0] : '' }}</strong>
      </p>

      <!-- Metric Selector -->
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

      <!-- Chart Header + Progress -->
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
            <span>
              {{ Math.abs(percentChange) }}% from previous
              {{ timeFrame === 'daily' ? 'day' : 'week' }}
            </span>
          </div>
        </div>

        <div class="text-center">
          <VCircularProgress
            :model-value="circleValue"
            color="primary"
            size="70"
            width="6"
          />
          <div class="text-caption mt-2">
            Today:
            {{
              getFormattedValue(
                selectedMetric.value,
                activeStats.at(-1)?.[selectedMetric.value]
              )
            }}
          </div>
          <div class="text-caption text-medium-emphasis">
            Avg: {{ averageDisplay }}
          </div>
        </div>
      </div>

      <!-- 📊 Chart -->
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
  import { ref, computed, onMounted, watch } from 'vue'
  import { useRoute } from 'vue-router'
  import VueApexCharts from 'vue3-apexcharts'
  import upArrow from '@/assets/images/cards/up.png'
  import downArrow from '@/assets/images/cards/down.png'
  import entry from '@/assets/images/cards/fitbit-watch.png'
  import baby from '@/assets/images/cards/chart-success.png'

  const ApexChart = VueApexCharts
  const route = useRoute()
  const babyId = route.params.id
  const babyName = ref('')
  const babyAgeWeeks = ref(0)
  const dateMenu = ref(false)

  const stats = ref([])
  const weeklyStats = ref([])
  const chartReady = ref(false)
  const selectedMetric = ref('totalFeeds')
  const activeTab = ref('summary')
  const timeFrame = ref('daily')
  const currentCycle = ref(0)
  const entriesToday = ref(0)
  const selectedDate = ref(new Date()) // store as Date object, not string
  const rangeDays = 7
  const currentWeekLabel = ref(null)
  const dailyThresholds = ref(null)
const weeklyThresholds = ref(null)

  try {
    const res = await $api(`/babies/${babyId}`, { method: 'GET' })
    babyName.value = res.name || 'Baby'
    const dob = new Date(res.dob._seconds * 1000)
    const now = new Date()
    const ageInMs = now - dob
    const ageInWeeks = Math.floor(ageInMs / (1000 * 60 * 60 * 24 * 7))
    babyAgeWeeks.value = ageInWeeks
  } catch (e) {
    console.error('Failed to fetch baby profile:', e)
  }

  async function updateStatsForSelectedDate() {
  if (timeFrame.value === 'daily') {
    await fetchDailyStats()
  } else {
    // Weekly mode — find the matching week
    const picked = new Date(selectedDate.value)
    const week = weeklyStats.value.find(w => {
      const start = new Date(w.startDate)
      const end = new Date(w.endDate)
      return picked >= start && picked <= end
    })
    if (week) {
      currentWeekLabel.value = `${week.startDate} → ${week.endDate}`
      stats.value = [week]
    } else {
      currentWeekLabel.value = null
      stats.value = []
    }
  }
}

  async function fetchJournalEntries() {
    try {
      const res = await $api(`/journalEntries/${babyId}`, { method: 'GET' })
      const entries = res || []
      currentCycle.value = Math.max(...entries.map(e => e.cycleNo || 0))
      const today = new Date().toISOString().split('T')[0]
      entriesToday.value = entries.filter(e => {
        const awakeDate = new Date(e.awakeTime._seconds * 1000).toISOString().split('T')[0]
        return awakeDate === today
      }).length
    } catch (err) {
      console.error('Failed to fetch journal entries:', err)
    }
  }

  async function fetchThresholds() {
  try {
    const [dailyRes, weeklyRes] = await Promise.all([
      $api('/thresholds/daily', { method: 'GET' }),
      $api('/thresholds/weekly', { method: 'GET' })
    ])

    dailyThresholds.value = dailyRes[0]  // assuming your example response is an array
    weeklyThresholds.value = weeklyRes[0]
  } catch (err) {
    console.error('Failed to fetch thresholds:', err)
  }
}

function getThresholdStatus(metricKey) {
  const thresholds =
    timeFrame.value === 'daily' ? dailyThresholds.value : weeklyThresholds.value
  if (!thresholds)
    return { label: 'UNKNOWN', color: 'grey', message: 'No data' }

  const actualKey =
    timeFrame.value === 'weekly' && metricKey === 'monInterval'
      ? 'averageMonInterval'
      : metricKey

  const weekKey = `week${babyAgeWeeks.value}`
  console.log('Evaluating threshold for', actualKey, 'at', weekKey)
  const metric = thresholds[actualKey]
  if (!metric || !metric.value || metric.value[weekKey] === undefined)
    return { label: 'UNKNOWN', color: 'grey', message: 'No threshold' }

  const thresholdVal = metric.value[weekKey]
  const actualVal = activeStats.value.at(-1)?.[metricKey]

  const parse = (v) => {
    if (typeof v === 'string' && v.includes(':')) {
      const [h, m] = v.split(':').map(Number)
      return h * 60 + m
    }
    return Number(v)
  }

  const tVal = parse(thresholdVal)
  const aVal = parse(actualVal)
  if (isNaN(tVal) || isNaN(aVal))
    return { label: 'UNKNOWN', color: 'grey', message: 'Invalid data' }

  // 🔹 Define which metrics should invert (lower = better)
  const invertedMetrics = [
    'totalCyclesBeyond3Hrs',
    'averageLapseDuration',
    'lapseDuration', // just in case naming differs
  ]
  const invertLogic = invertedMetrics.includes(metricKey)

  // 🔹 Compare properly based on metric type
  const meetsTarget = invertLogic ? aVal <= tVal : aVal >= tVal

  // 🔹 Determine status + color
  const label = meetsTarget ? metric.label.above : metric.label.below
  const message = meetsTarget ? metric.message.above : metric.message.below
  const color = label === 'ALERT' ? 'error' : label === 'NORMAL' ? 'success' : 'grey'

  return { label, color, message }
}




  async function fetchWeeklyStats() {
    try {
      const res = await $api(`/statistics/weekly/baby/${babyId}`, { method: 'GET' })
      weeklyStats.value = res.data?.statistics.map((s, index) => ({
        day: s.week || index + 1,
        totalFeeds: s.totalFeeds,
        totalUrineCount: s.totalUrineCount,
        totalStoolCount: s.totalStoolCount,
        totalSleepDuration: s.totalSleepDuration,
        totalPlayDuration: s.totalPlayDuration,
        totalCyclesBeyond3Hrs: s.totalCyclesBeyond3Hrs,
        monInterval: s.averageMonInterval,
        averageMilkIntake: s.averageMilkIntake,
        averagePlayDuration: s.averagePlayDuration,
        averageLapseDuration: s.averageLapseDuration,
      }))
    } catch (err) {
      console.error('Failed to load weekly stats:', err)
    }
  }

  async function fetchDailyStats() {
    try {
      const res = await $api(`/statistics/daily/baby/${babyId}`, { method: 'GET' })
      const allStats = res.data?.statistics || []

      // ensure selectedDate is a Date object
      const endDate = new Date(selectedDate.value)  
      const startDate = new Date(endDate) 
      startDate.setDate(endDate.getDate() - rangeDays +1)

      const filteredStats = []
      for (let i = 0; i < rangeDays; i++) {
        const currentDate = new Date(startDate)
        currentDate.setDate(startDate.getDate() + i)

        const isoDate = currentDate.toISOString().split('T')[0] // convert to YYYY-MM-DD string
        const dayData = allStats.find(d => d.date === isoDate)  

        filteredStats.push(dayData ? { ...dayData, date: isoDate } : {
          date: isoDate,
          totalFeeds: 0,
          totalUrineCount: 0,
          totalStoolCount: 0,
          totalCyclesBeyond3Hrs: 0,
          totalSleepDuration: '00:00',
          totalPlayDuration: '00:00',
          monInterval: '00:00',
          averagePlayDuration: '00:00',
          averageLapseDuration: '00:00',
          averageMilkIntake: 0,
        })
      }

      stats.value = filteredStats
      chartReady.value = true
    } catch (err) {
      console.error('Failed to load daily stats:', err)
    }
  }



  watch(selectedDate, updateStatsForSelectedDate)


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
    const data = timeFrame.value === 'daily' ? stats.value : weeklyStats.value
    return [...data].sort((a, b) => (a.date || a.day) > (b.date || b.day) ? 1 : -1)
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

  async function updateSummary() {
  if (timeFrame.value === 'daily') {
    await fetchDailyStats()
  } else {
    const picked = new Date(summaryDate.value)
    const week = weeklyStats.value.find(w => {
      const start = new Date(w.startDate)
      const end = new Date(w.endDate)
      return picked >= start && picked <= end
    })
    if (week) {
      currentWeekLabel.value = `${week.startDate} → ${week.endDate}`
      stats.value = [week]
    } else {
      currentWeekLabel.value = null
      stats.value = []
    }
  }
}

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
    chart: {
      id: 'baby-stats-chart',
      toolbar: { show: false },
      foreColor: '#ccc',
    },
    stroke: { curve: 'smooth', width: 3 },
    xaxis: {
      categories: activeStats.value.map((s, i) =>
        timeFrame.value === 'weekly' ? `Week ${s.day}` : s.date || `Day ${s.day}`
      ),
      labels: { style: { colors: '#ccc', fontSize: '12px' } },
    },
    yaxis: {
      title: {
        text: currentLabel.value,
        style: {
          color: '#ccc',
          fontSize: '14px',
          fontWeight: 500,
        },
      },
      labels: { style: { colors: '#ccc', fontSize: '12px' } },
      min: 0,
      tickAmount: 4,
    },
    colors: ['#7367F0'],
  }))

  const currentLabel = computed(() =>
    metricOptions.find(opt => opt.value === selectedMetric.value)?.title || selectedMetric.value
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

  onMounted(async () => {
  await Promise.all([
    fetchThresholds(),
    fetchDailyStats(),
    fetchWeeklyStats(),
    fetchJournalEntries(),
  ])
})

  </script>
