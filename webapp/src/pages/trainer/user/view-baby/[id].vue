<template>
  <div class="pa-4">
    <VCard class="pa-2">
<VCardTitle class="d-flex align-center justify-space-between pr-4">
  <div class="text-h6">Baby Schedule for {{ babyName || '...' }}</div>

  <div class="d-flex align-center">
    <!-- Date Picker -->
    <VMenu v-model="datePickerMenu" :close-on-content-click="false" location="bottom end">
      <template #activator="{ props }">
        <VBtn color="primary" v-bind="props" variant="flat" size="small">📅 Jump to Date</VBtn>
      </template>
      <VCard class="pa-2">
        <VDatePicker
          v-model="selectedDate"
          show-adjacent-months
          color="primary"
          @update:modelValue="onDatePicked"
        />
      </VCard>
    </VMenu>

    <!-- 🔄 Toggle -->
    <VBtn
      variant="tonal"
      color="primary"
      size="small"
      class="ml-3"
      @click="goToOtherPage"
    >
      🔄 Switch to Statistics
    </VBtn>
  </div>
</VCardTitle>


      <VCardText>
        <FullCalendar ref="calendarRef" :options="calendarOptions" />
      </VCardText>
    </VCard>

    <!-- Entry Drawer -->
    <VNavigationDrawer v-model="isDrawerOpen" location="end" temporary width="420">
      <VToolbar density="comfortable" title="Entry Details" />
      <div class="pa-4">
        <div v-if="entryDetails">
          <div class="text-subtitle-1 mb-3">
            {{ formatDateTime(entryDetails.awakeTime) }}
            <span class="text-medium-emphasis"></span>
          </div>

          <VList density="compact" lines="two">
            <VListItem>
              <VListItemTitle>📘 Entry #</VListItemTitle>
              <VListItemSubtitle>{{ safe(entryDetails.entryNo) }}</VListItemSubtitle>
            </VListItem>

            <VDivider class="my-2" />

            <VListItem>
              <VListItemTitle>🕓 Awake Time</VListItemTitle>
              <VListItemSubtitle>{{ formatDateTime(entryDetails.awakeTime) }}</VListItemSubtitle>
            </VListItem>

            <VListItem>
              <VListItemTitle>🍼 Feed Start</VListItemTitle>
              <VListItemSubtitle>{{ formatDateTime(entryDetails.startFeedTime) }}</VListItemSubtitle>
            </VListItem>

            <VListItem v-if="prettyFeedTypes(entryDetails.feedType)">
              <VListItemTitle>🍼 Feed Details</VListItemTitle>
              <VListItemSubtitle>{{ prettyFeedTypes(entryDetails.feedType) }}</VListItemSubtitle>
            </VListItem>

            <VListItem>
              <VListItemTitle>🎈 Play Start</VListItemTitle>
              <VListItemSubtitle>{{ formatDateTime(entryDetails.startPlayTime) }}</VListItemSubtitle>
            </VListItem>

            <VListItem>
              <VListItemTitle>😴 Sleep Start</VListItemTitle>
              <VListItemSubtitle>{{ formatDateTime(entryDetails.startSleepTime) }}</VListItemSubtitle>
            </VListItem>

            <VListItem>
              <VListItemTitle>💤 Sleep Duration</VListItemTitle>
              <VListItemSubtitle>{{ formatDurationHours(entryDetails.sleepDuration) }}</VListItemSubtitle>
            </VListItem>

            <template v-for="(val, key) in extraFields(entryDetails)" :key="key">
              <VListItem>
                <VListItemTitle>{{ key }}</VListItemTitle>
                <VListItemSubtitle>{{ val }}</VListItemSubtitle>
              </VListItem>
            </template>
          </VList>

          <VDivider class="my-3" />
          <VBtn color="primary" block @click="isDrawerOpen = false">Close</VBtn>
        </div>

        <div v-else class="text-medium-emphasis">
          Select an entry from the calendar to view details.
        </div>
      </div>
    </VNavigationDrawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
  import { useRoute, useRouter } from "vue-router"
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
import '@core/scss/template/libs/full-calendar.scss'

/* ---------- State ---------- */
const route = useRoute()
const router = useRouter()
const babyId = computed(() => route.params.id)
const babyName = ref('')
const calendarRef = ref(null)
const isDrawerOpen = ref(false)
const entryDetails = ref(null)
const events = ref([])
const currentView = ref('dayGridMonth')
const datePickerMenu = ref(false)
const selectedDate = ref(null)

/* ---------- Utility Functions ---------- */
function tsToIso(ts) {
  if (!ts) return null
  if (typeof ts === 'string') return new Date(ts).toISOString()
  if (typeof ts._seconds === 'number') return new Date(ts._seconds * 1000).toISOString()
  if (typeof ts.seconds === 'number') return new Date(ts.seconds * 1000).toISOString()
  return null
}

function formatDateTime(ts) {
  if (!ts) return '—'
  const d = typeof ts === 'object' && ts._seconds ? new Date(ts._seconds * 1000) : new Date(ts)
  if (isNaN(d.getTime())) return '—'
  return d.toLocaleString(undefined, {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function safe(val, suffix = '') {
  return val === null || val === undefined || val === '' ? '—' : `${val}${suffix}`
}

function prettyFeedTypes(feedType) {
  return (Array.isArray(feedType) ? feedType : [])
    .map(f => {
      const unit = f.unit || ''
      const value = typeof f.value === 'number' ? f.value : ''
      const name = f.name ?? f.type ?? ''
      return [name, value && unit ? `${value} ${unit}` : ''].filter(Boolean).join(' • ')
    })
    .filter(Boolean)
    .join(', ')
}

function formatDurationHours(hoursFloat) {
  if (!hoursFloat || typeof hoursFloat !== 'number') return '—'
  const hours = Math.floor(hoursFloat)
  const minutes = Math.round((hoursFloat - hours) * 60)
  return [hours && `${hours} ${hours === 1 ? 'Hour' : 'Hours'}`, minutes && `${minutes} ${minutes === 1 ? 'Minute' : 'Minutes'}`]
    .filter(Boolean).join(' ')
}

function extraFields(entry) {
  const used = new Set(['id', 'cycleNo', 'awakeTime', 'startFeedTime', 'startPlayTime', 'startSleepTime', 'sleepDuration', 'feedType','iso','timestamp','entryNo','dateKey'])
  const labelMap = {
    hasStool: 'Has the baby pooped?',
    hasUrine: 'Has the baby peed?',
    remarks: 'Remarks',
    status: 'Entry Status',
  }

  const out = {}
  for (const k in entry) {
    if (used.has(k)) continue
    const label = labelMap[k] || k
    const val = entry[k]
    out[label] =
      k === 'hasStool' || k === 'hasUrine' ? (val === true ? 'Yes ✅' : val === false ? 'No ❌' : '—') :
      k === 'status' ? { COMPLETE: 'Complete ✅', INCOMPLETE: 'Incomplete ⚠️' }[val] || val :
      typeof val === 'boolean' ? (val ? 'Yes' : 'No') :
      val && typeof val === 'object' && '_seconds' in val ? formatDateTime(val) :
      typeof val === 'string' || typeof val === 'number' ? val : JSON.stringify(val)
  }

  return out
}

function getLocalDateKeyFromAwakeTime(isoString) {
  return new Date(isoString).toLocaleDateString('en-CA') // YYYY-MM-DD
}

/* ---------- Data Loading ---------- */
async function loadBabyInfo() {
  try {
    const id = babyId.value
    if (!id) return
    const res = await $api(`babies/${id}`, { method: 'GET' })
    babyName.value = res?.name || 'Unknown Baby'
  } catch (err) {
    console.error('Failed to load baby info', err)
  }
}

async function loadEntries() {
  try {
    const id = babyId.value
    if (!id) return

    const res = await $api(`journalEntries/${id}`, { method: 'GET' })
    const list = Array.isArray(res) ? res : []

    const normalized = list
      .map(e => {
        const iso = tsToIso(e.awakeTime)
        if (!iso) return null
        return {
          ...e,
          iso,
          timestamp: new Date(iso).getTime(),
          dateKey: getLocalDateKeyFromAwakeTime(iso),
        }
      })
      .filter(Boolean)
      .sort((a, b) => a.timestamp - b.timestamp)

    const grouped = {}
    const calendarEvents = []

    for (const entry of normalized) {
      const { id, dateKey, iso } = entry
      if (!grouped[dateKey]) grouped[dateKey] = []
      if (grouped[dateKey].some(e => e.id === id)) continue

      const entryNo = grouped[dateKey].length + 1
      entry.entryNo = entryNo
      grouped[dateKey].push(entry)

      calendarEvents.push({
        id: `${id}-${dateKey}`,
        title: `Entry #${entryNo}`,
        start: new Date(iso),
        allDay: false,
        display: 'list-item',
        extendedProps: {
          type: 'entry',
          icon: '📘',
          details: entry,
        },
      })
    }

    events.value = calendarEvents
    await nextTick()
    calendarRef.value?.getApi()?.refetchEvents()
  } catch (err) {
    console.error('Failed to load journal entries', err)
  }
}

/* ---------- Calendar Setup ---------- */
const calendarOptions = ref({
  plugins: [dayGridPlugin],
  initialView: 'dayGridMonth',
  timezone: 'local',
  headerToolbar: {
    left: 'prev,next today',
    center: 'title',
    right: '',
  },
  height: 'auto',
  expandRows: true,
  nowIndicator: true,
  dayMaxEvents: 3,
  moreLinkClick: 'popover',
  eventTimeFormat: { hour: 'numeric', minute: '2-digit', meridiem: 'short' },
  events: computed(() => events.value),
  datesSet(arg) {
    currentView.value = arg.view.type
  },
  eventClick(info) {
    const entry = info.event.extendedProps?.details
    if (!entry) return
    entryDetails.value = entry
    isDrawerOpen.value = true
  },
  eventContent(arg) {
    const icon = arg.event.extendedProps?.icon || ''
    const time = arg.timeText ? `${arg.timeText} ` : ''
    const title = arg.event.title?.split('(')[0]?.trim() || arg.event.title
    const el = document.createElement('div')
    el.className = 'fc-pill fc-pill--month'
    el.innerText = `${time}${icon} ${title}`
    return { domNodes: [el] }
  },
})

const isStatsPage = computed(() =>
  route.path.includes('/trainer/user/view-stats/')
)

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

/* ---------- Lifecycle ---------- */
onMounted(async () => {
  await loadBabyInfo()
  await loadEntries()
})
watch(babyId, async () => {
  await loadBabyInfo()
  await loadEntries()
})

function onDatePicked(dateStr) {
  datePickerMenu.value = false
  calendarRef.value?.getApi()?.gotoDate(dateStr)
}
</script>

<style scoped>
.fc .fc-daygrid-event,
.fc .fc-timegrid-event {
  border-radius: 8px;
  padding: 0;
  overflow: hidden;
  border: 0 !important;
}
.fc .fc-timegrid-event .fc-event-main {
  padding: 2px 6px;
  font-size: 12px;
  line-height: 16px;
}
.fc-pill {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.fc-pill--month {
  padding: 1px 4px;
  font-size: 11px;
  line-height: 14px;
  white-space: normal;
  overflow-wrap: anywhere;
  word-break: break-word;
  width: 100%;
  box-sizing: border-box;
}
</style>
