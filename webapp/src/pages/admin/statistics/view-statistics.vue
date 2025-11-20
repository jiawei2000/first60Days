<template>
    <VCard title="Admin Statistics">
        <VCardText>
            <!-- 📊 Tab Switch -->
            <VTabs v-model="activeTab" background-color="transparent" grow class="mb-4">
                <VTab value="age">By Age</VTab>
                <VTab value="gender">By Gender</VTab>
            </VTabs>

            <VDivider class="mb-4" />

            <VWindow v-model="activeTab">
                <!-- 🔹 AGE STATS -->
                <VWindowItem value="age">
                    <VSelect v-model="selectedAgeMetric" :items="metricOptions" label="Select Metric" item-title="label"
                        item-value="value" variant="outlined" hide-details class="mb-4 mt-1" />

                    <div v-if="chartReady && ageChartSeries?.[0]?.data?.length">
                        <ApexChart type="line" height="300" :options="ageChartOptions" :series="ageChartSeries" />
                    </div>
                    <div v-else class="text-medium-emphasis text-center mt-4">
                        No data available for age stats.
                    </div>
                </VWindowItem>

                <!-- 🔹 GENDER STATS -->
                <VWindowItem value="gender">
                    <VSelect v-model="selectedGenderMetric" :items="metricOptions" label="Select Metric"
                        item-title="label" item-value="value" variant="outlined" hide-details class="mb-4 mt-1" />

                    <div v-if="chartReady && genderChartSeries?.[0]?.data?.length">
                        <ApexChart type="line" height="300" :options="genderChartOptions" :series="genderChartSeries" />
                    </div>
                    <div v-else class="text-medium-emphasis text-center mt-4">
                        No data available for gender stats.
                    </div>
                </VWindowItem>
            </VWindow>
        </VCardText>
    </VCard>
</template>


<script setup>
import { ref, onMounted, computed } from 'vue'
import VueApexCharts from 'vue3-apexcharts'
import { format } from 'date-fns'

const ApexChart = VueApexCharts

const activeTab = ref('age')
const chartReady = ref(false)

const selectedGenderMetric = ref('averageTotalFeed')
const selectedAgeMetric = ref('averageTotalFeed')

const genderStats = ref([])
const ageStats = ref([])

const metricOptions = [
  { label: 'Average Feeds', value: 'averageTotalFeed' },
  { label: 'Average Urine Count', value: 'averageTotalUrineCount' },
  { label: 'Average Stool Count', value: 'averageTotalStoolCount' },
    { label: 'Average Sleep Duration', value: 'averageSleepDuration' },
    { label: 'Average Play Duration', value: 'averagePlayDuration' },
    { label: 'Average MON Interval', value: 'averageMonInterval' },
    { label: 'Average Milk Intake', value: 'averageMilkIntake' },
    { label: 'Total Babies', value: 'totalBabies' },
]

function parseDuration(str) {
  if (!str || typeof str !== 'string') return 0
  const [h, m] = str.split(':').map(Number)
  return h * 60 + m
}

function isDuration(metric) {
  return ['averageSleepDuration', 'averagePlayDuration', 'averageMonInterval'].includes(metric)
}

// Fetch gender stats
async function fetchGenderStats() {
  try {
    const res = await $api('/statistics/gender')
    genderStats.value = res.data?.statistics || []
    chartReady.value = true
  } catch (err) {
    console.error('Error fetching gender stats:', err)
  }
}

// Fetch age group stats
async function fetchAgeStats() {
  try {
    const res = await $api('/statistics/ageGroup')
    ageStats.value = res.data?.statistics || []
    chartReady.value = true
  } catch (err) {
    console.error('Error fetching age stats:', err)
  }
}

// Gender Chart Series
const genderChartSeries = computed(() => {
  const metric = selectedGenderMetric.value
  const maleData = genderStats.value.map(s =>
    isDuration(metric) ? parseDuration(s.maleStatistics[metric]) : s.maleStatistics[metric]
  )
  const femaleData = genderStats.value.map(s =>
    isDuration(metric) ? parseDuration(s.femaleStatistics[metric]) : s.femaleStatistics[metric]
  )
  return [
    { name: 'Male', data: maleData },
    { name: 'Female', data: femaleData },
  ]
})

const genderChartOptions = computed(() => ({
  chart: { id: 'gender-stats', toolbar: { show: false }, foreColor: '#ccc' },
  stroke: { curve: 'smooth', width: 3 },
  xaxis: {
    categories: genderStats.value.map(s => format(new Date(s.date), 'MMM d')),
    labels: { style: { colors: '#ccc', fontSize: '12px' } },
  },
  yaxis: {
    labels: {
      style: { colors: '#ccc', fontSize: '12px' },
      formatter: val =>
        isDuration(selectedGenderMetric.value)
          ? `${Math.floor(val / 60)}h ${Math.round(val % 60)}m`
          : val?.toFixed?.(1) ?? 0,
    },
    min: 0,
    tickAmount: 4,
  },
  tooltip: {
  theme: 'dark',
  style: {
    fontSize: '12px',
    color: '#FFFFFF'
  }
},
  colors: ['#42A5F5', '#FF7043'],
}))

// Age Group Chart
const ageChartCategories = computed(() => {
  const weeks = new Set()
  ageStats.value.forEach(entry => {
    Object.keys(entry.ageGroupStatistics || {}).forEach(week => {
      weeks.add(week)
    })
  })
  return Array.from(weeks).sort((a, b) => +a.replace('week', '') - +b.replace('week', ''))
})

const ageChartSeries = computed(() => {
  const metric = selectedAgeMetric.value
  const valuesPerWeek = {}

  ageStats.value.forEach(entry => {
    const stats = entry.ageGroupStatistics || {}
    for (const [week, weekData] of Object.entries(stats)) {
      if (!valuesPerWeek[week]) valuesPerWeek[week] = []
      const rawValue = weekData[metric]
      const parsed = isDuration(metric) ? parseDuration(rawValue) : rawValue
      valuesPerWeek[week].push(parsed || 0)
    }
  })

  const seriesData = ageChartCategories.value.map(week => {
    const values = valuesPerWeek[week] || []
    const avg = values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0
    return parseFloat(avg.toFixed(1))
  })

  return [
    {
      name: 'Average by Week',
      data: seriesData,
    },
  ]
})

const ageChartOptions = computed(() => ({
  chart: { id: 'age-stats', toolbar: { show: false }, foreColor: '#ccc' },
  stroke: { curve: 'smooth', width: 3 },
  xaxis: {
    categories: ageChartCategories.value,
    labels: { style: { colors: '#ccc', fontSize: '12px' } },
  },
  yaxis: {
    labels: {
      style: { colors: '#ccc', fontSize: '12px' },
      formatter: val =>
        isDuration(selectedAgeMetric.value)
          ? `${Math.floor(val / 60)}h ${Math.round(val % 60)}m`
          : val?.toFixed?.(1) ?? 0,
    },
    min: 0,
    tickAmount: 4,
  },
  tooltip: {
  theme: 'dark',
  style: {
    fontSize: '12px',
    color: '#FFFFFF'
  }
},
  colors: ['#66BB6A'],
}))

onMounted(() => {
  fetchGenderStats()
  fetchAgeStats()
})
</script>
