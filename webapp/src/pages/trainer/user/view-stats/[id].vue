<template>
  <div>
    <!-- 🧠 Page Header -->
<div class="d-flex align-center justify-space-between mb-4">
  <h2 class="text-h4 font-weight-bold">Statistics for {{ babyName }}</h2>

  <div class="d-flex align-center">
    <VBtnToggle
      v-model="timeFrame"
      divided
      color="primary"
      density="comfortable"
      class="mr-4"
    >
      <VBtn value="daily">Daily</VBtn>
      <VBtn value="weekly">Weekly</VBtn>
    </VBtnToggle>

    <!-- 🔄 Toggle -->
    <VBtn
      variant="tonal"
      color="primary"
      size="small"
      @click="goToOtherPage"
    >
      🔄 Switch to Schedule
    </VBtn>
  </div>
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

        <!-- 🧭 Shared Date Picker -->
        <div v-if="timeFrame === 'daily'" class="d-flex align-center justify-end mb-2" style="position: relative; z-index: 10;">
          <VMenu
            v-model="dateMenu.value"
            transition="scale-transition"
            location="bottom end"
            offset-y
            max-width="290"
            min-width="auto"
            :close-on-content-click="false"
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
                {{ selectedDate ? formatLocalDate(selectedDate) : 'Select date' }}

              </VBtn>
            </template>

            <VDatePicker
              v-model="selectedDate"
              color="primary"
              :max="new Date()"
              @update:modelValue="() => {
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

            <!-- Week Dropdown (Weekly Only) -->
<div v-if="timeFrame === 'weekly'" class="mb-4" style="max-width: 200px;">
  <VSelect
    v-model="selectedWeek"
    :items="weekOptions"
    item-title="title"
    item-value="value"
    label="Select Week"
    density="comfortable"
    variant="outlined"
    hide-details
  />
</div>


            <p
              v-if="timeFrame === 'weekly' && currentWeekLabel"
              class="text-caption text-medium-emphasis mb-4"
            >
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

                    <!-- ICON + TITLE -->
                    <div>
                      <p class="text-subtitle-1 font-weight-medium mb-1">
                        <!-- 🎨 ICONS INSERTED HERE -->
                        <span v-if="metric.value === 'totalFeeds'">🍼 </span>
                        <span v-else-if="metric.value === 'totalUrineCount'">🚽 </span>
                        <span v-else-if="metric.value === 'totalStoolCount'">💩 </span>
                        <span v-else-if="metric.value === 'totalSleepDuration'">😴 </span>
                        <span v-else-if="metric.value === 'totalPlayDuration'">🎈 </span>
                        <span v-else-if="metric.value === 'monInterval'">⏱ </span>
                        <span v-else-if="metric.value === 'averagePlayDuration'">🎡 </span>
                        <span v-else-if="metric.value === 'averageLapseDuration'">⏲ </span>
                        <span v-else-if="metric.value === 'averageMilkIntake'">🍼 </span>
                        <span v-else-if="metric.value === 'totalCyclesBeyond3Hrs'">🔁 </span>

                        {{ metric.title }}
                      </p>

                      <p class="text-body-2 text-medium-emphasis mb-0">
                        Current: {{ formatMetric(metric.value, latestValue(metric.value)) }}
                      </p>
                      <p class="text-body-2 text-medium-emphasis mb-0">
                        Average To Date: {{ getAverage(metric.value) }}
                      </p>
                    </div>

                    <!-- STATUS CHIP -->
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
              <strong>{{ selectedDate ? formatLocalDate(selectedDate) : '' }}</strong>

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

            <!-- Chart Heading -->
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
                </div>
                <div class="text-caption text-medium-emphasis">
                  Avg: {{ averageDisplay }}
                </div>
              </div>
            </div>

            <!-- LINE CHART -->
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
  import VueApexCharts from 'vue3-apexcharts'
  import upArrow from '@/assets/images/cards/up.png'
  import downArrow from '@/assets/images/cards/down.png'
  import entry from '@/assets/images/cards/fitbit-watch.png'
  import baby from '@/assets/images/cards/chart-success.png'
  import { useRoute, useRouter } from "vue-router"

  const ApexChart = VueApexCharts
const route = useRoute()
const router = useRouter()
  const babyId = route.params.id
  const babyName = ref('')
  const babyAgeWeeks = ref(0)
  const dateMenu = ref({ value: false })

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
const selectedWeek = ref(null)

  try {
    const res = await $api(`/babies/${babyId}`, { method: 'GET' })
    babyName.value = res.name || 'Baby'
  } catch (e) {
    console.error('Failed to fetch baby profile:', e)
  }
  const weekOptions = computed(() =>
  weeklyStats.value.map(w => ({
    title: `Week ${w.day}`,
    value: w.day
  }))
)

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

    // ✅ FIXED: use local date instead of UTC ISO
    const today = formatLocalDate(new Date())

    entriesToday.value = entries.filter(e => {
      const awakeDate = formatLocalDate(new Date(e.awakeTime._seconds * 1000))
      return awakeDate === today
    }).length

  } catch (err) {
    console.error('Failed to fetch journal entries:', err)
  }
}


  function formatLocalDate(d) {
  return d.toLocaleDateString('en-CA') // YYYY-MM-DD
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

    const statsArr = res.data?.statistics || []

    weeklyStats.value = statsArr.map((s, index) => ({
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
      startDate: s.startDate,
      endDate: s.endDate,
      rawWeek: s.week
    }))

    // 🔥 SET BABY AGE BASED ON LATEST WEEK NUMBER
if (statsArr.length > 0) {
  const latest = statsArr[statsArr.length - 1]
  babyAgeWeeks.value = latest.week

  // Set dropdown default to the latest week
  selectedWeek.value = latest.week

  // Set summary stats to that week
  stats.value = [latest]
  currentWeekLabel.value = `${latest.startDate} → ${latest.endDate}`
}

  } catch (err) {
    console.error('Failed to load weekly stats:', err)
  }
}

function updateSelectedWeek() {
  if (!selectedWeek.value) return
  const selected = weeklyStats.value.find(w => w.day === selectedWeek.value)
  if (selected) {
    stats.value = [selected]
    currentWeekLabel.value = `${selected.startDate} → ${selected.endDate}`
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

        const isoDate = formatLocalDate(currentDate)// convert to YYYY-MM-DD string
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
  watch(selectedWeek, updateSelectedWeek)



  const metricOptions = [
    { title: 'Total Feeds', value: 'totalFeeds' },
    { title: 'Total Urine Count', value: 'totalUrineCount' },
    { title: 'Total Stool Count', value: 'totalStoolCount' },
    { title: 'Cycles Beyond 3 hours', value: 'totalCyclesBeyond3Hrs' },
    { title: 'Total Sleep Duration(HH:MM)', value: 'totalSleepDuration' },
    { title: 'Total Play Duration(HH:MM)', value: 'totalPlayDuration' },
    { title: 'MON Interval(HH:MM)', value: 'monInterval' },
    { title: 'Avg Play Duration Per Entry(HH:MM)', value: 'averagePlayDuration' },
    { title: 'Lapse Duration(HH:MM)', value: 'averageLapseDuration' },
    { title: 'Avg Milk Intake Per Entry', value: 'averageMilkIntake' },
  ]

const activeStats = computed(() => {
  if (timeFrame.value === 'daily') {
    return [...stats.value].sort((a, b) => (a.date > b.date ? 1 : -1))
  }

  // WEEKLY MODE — use only the selected week's stats
  const selected = weeklyStats.value.find(w => w.day === selectedWeek.value)
  if (!selected) return []

  return [selected]
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
function formatMetric(metric, value) {
  if (!metric || value === undefined || value === null) {
    return '0'
  }

  if (isDurationField(metric)) {
    const totalMin = parseDuration(value)
    const h = Math.floor(totalMin / 60)
    const m = Math.round(totalMin % 60)
    return `${h}h ${m}m`
  }

  return Number(value).toFixed(2)
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
    return avg.toFixed(2)
  }

const chartSeries = computed(() => {
  const metric = selectedMetric.value
  const source = timeFrame.value === 'weekly' ? weeklyStats.value : activeStats.value

  return [
    {
      name: metric,
      data: source.map(s =>
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
  categories: (timeFrame.value === 'weekly' ? weeklyStats.value : activeStats.value)
    .map((s, i) =>
      timeFrame.value === 'weekly'
        ? `Week ${s.day}`
        : s.date || `Day ${s.day}`
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
  labels: {
    style: { colors: '#ccc', fontSize: '12px' },
    formatter: (val) => {
      // Duration metrics use minutes internally -> convert to HH:MM
      if (isDurationField(selectedMetric.value)) {
        if (!val || isNaN(val)) return '00:00'

        const hours = Math.floor(val / 60)
        const mins = Math.floor(val % 60)
        const h = hours.toString().padStart(2, '0')
        const m = mins.toString().padStart(2, '0')
        return `${h}:${m}`
      }

      // Non-duration metrics -> just show raw number
      return Number(val).toFixed(0)
    }
  },
  min: 0,
  tickAmount: 4,
}
,tooltip: {
    theme: 'dark',
    style: {
      fontSize: '12px',
      color: '#FFFFFF'
    }
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
    return total.toFixed(2)
  })

  const isStatsPage = computed(() =>
  route.path.includes('/trainer/user/view-stats/')
)

function getTodayValue(metric) {
  const todayRow = activeStats.value.at(-1)
  if (!todayRow) return 0
  return todayRow[metric] ?? 0
}

function goToOtherPage() {
  console.log('clicked')
  const id = route.params.id

  if (isStatsPage.value) {
    // go to baby schedule
    router.push(`/trainer/user/view-baby/${id}`)
  } else {
    // go to baby stats
    router.push(`/trainer/user/view-stats/${id}`)
  }
}

  const averageDisplay = computed(() => getAverage(selectedMetric.value))

  const percentChange = computed(() => {
    const metric = selectedMetric.value
    const today = activeStats.value.at(-1)?.[metric]
    const prev = activeStats.value.at(-2)?.[metric]
    const t = isDurationField(metric) ? parseDuration(today) : Number(today)
    const p = isDurationField(metric) ? parseDuration(prev) : Number(prev)
    if (isNaN(t) || isNaN(p) || p === 0) return null
    return parseFloat(((t - p) / p * 100).toFixed(2))
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
