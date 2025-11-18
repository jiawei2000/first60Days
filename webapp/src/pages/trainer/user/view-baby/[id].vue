<template>
  <div class="pa-4">
    <VCard class="pa-2">
      <VCardTitle class="d-flex align-center justify-space-between pr-4">
        <div>
          <div class="text-h6">Baby Schedule for {{ babyName || '...' }}</div>
        </div>

        <!-- Date Picker Menu -->
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
      </VCardTitle>


      <VCardText>
        <FullCalendar ref="calendarRef" :options="calendarOptions" />
      </VCardText>
    </VCard>

    <!-- Right Drawer: Entry Details -->
    <VNavigationDrawer v-model="isDrawerOpen" location="end" temporary width="420">
      <VToolbar density="comfortable" title="Entry Details" />
      <div class="pa-4">
        <div v-if="entryDetails">
          <div class="text-subtitle-1 mb-3">
            {{ formatDateTime(entryDetails.awakeTime) }}
            <span class="text-medium-emphasis">(Entry time)</span>
          </div>

          <VList density="compact" lines="two">
            <VListItem>
              <VListItemTitle>Cycle #</VListItemTitle>
              <VListItemSubtitle>{{ safe(entryDetails.cycleNo) }}</VListItemSubtitle>
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
              <VListItemSubtitle>{{ safe(entryDetails.sleepDuration, ' hrs') }}</VListItemSubtitle>
            </VListItem>

            <!-- Generic passthrough for any extra fields you might add later -->
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
import { useRoute } from 'vue-router'
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
// import timeGridPlugin from '@fullcalendar/timegrid'
// import interactionPlugin from '@fullcalendar/interaction'
import listPlugin from '@fullcalendar/list'
import '@core/scss/template/libs/full-calendar.scss'

definePage({ meta: { trainerOnly: true } })

const route = useRoute()
const babyId = computed(() => route.params.id)
const babyName = ref('')

const calendarRef = ref(null)
const isDrawerOpen = ref(false)
const entryDetails = ref(null)
const events = ref([])
const currentView = ref('dayGridMonth')

const datePickerMenu = ref(false)
const selectedDate = ref(null)

function onDatePicked(dateStr) {
  datePickerMenu.value = false
  if (calendarRef.value?.getApi) {
    calendarRef.value.getApi().gotoDate(dateStr)
  }
}


/* ---------- Helpers ---------- */
function tsToIso(ts) {
  if (!ts) return null
  if (typeof ts === 'string') return new Date(ts).toISOString()
  if (typeof ts._seconds === 'number') return new Date(ts._seconds * 1000).toISOString()
  if (typeof ts.seconds === 'number') return new Date(ts.seconds * 1000).toISOString()
  return null
}
function addMinutes(iso, minutes) {
  const d = new Date(iso)
  d.setMinutes(d.getMinutes() + (minutes || 0))
  return d.toISOString()
}
function formatDateTime(ts) {
  if (!ts) return '—'
  const d = typeof ts === 'object' && typeof ts._seconds === 'number'
    ? new Date(ts._seconds * 1000)
    : new Date(ts)
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
  if (val === null || val === undefined || val === '') return '—'
  return `${val}${suffix}`
}
function prettyFeedTypes(feedType) {
  if (!Array.isArray(feedType) || !feedType.length) return ''
  return feedType
    .map(f => {
      if (!f) return ''
      const unit = f.unit ? String(f.unit) : ''
      const value = typeof f.value === 'number' ? f.value : ''
      const name = f.name ?? f.type ?? ''
      return [name, value && unit ? `${value} ${unit}` : ''].filter(Boolean).join(' • ')
    })
    .filter(Boolean)
    .join(', ')
}
function extraFields(entry) {
  const used = new Set([
    'id', 'cycleNo',
    'awakeTime', 'startFeedTime', 'startPlayTime', 'startSleepTime',
    'sleepDuration', 'feedType',
  ])
  const out = {}
  for (const k in entry || {}) {
    if (used.has(k)) continue
    const v = entry[k]
    if (v && typeof v === 'object' && '_seconds' in v) {
      out[k] = formatDateTime(v)
    } else {
      out[k] = typeof v === 'string' || typeof v === 'number' ? v : JSON.stringify(v)
    }
  }
  return out
}

/* ---------- Load Baby Info ---------- */
async function loadBabyInfo() {
  try {
    const id = babyId.value
    if (!id) return
    const res = await $api(`babies/${id}`, { method: 'GET' })
    babyName.value = res?.name || 'Unknown Baby'
  } catch (err) {
    console.error('Failed to load baby info', err)
    babyName.value = 'Unknown Baby'
  }
}

/* ---------- Load + Map Entries as Events ---------- */
async function loadEntries() {
  try {
    const id = babyId.value
    if (!id) return
    const res = await $api(`journalEntries/${id}`, { method: 'GET' })
    const list = Array.isArray(res) ? res : []
    const mapped = []

    for (const e of list) {
      const awakeStart = tsToIso(e.awakeTime)
      if (!awakeStart) continue

      mapped.push({
  id: e.id,
  title: `Entry ${e.cycleNo ? `#${e.cycleNo}` : ''}`,
  start: awakeStart,
  allDay: false,
  display: 'list-item', // ✅ FORCES inline style
  extendedProps: { type: 'entry', icon: '📘', details: e },
})

    }

    events.value = mapped
    await nextTick()
    calendarRef.value?.getApi()?.refetchEvents()
  } catch (err) {
    console.error('Failed to load journal entries for calendar', err)
  }
}

/* ---------- Calendar Options ---------- */
const calendarOptions = ref({
  plugins: [dayGridPlugin, listPlugin], // Removed timeGridPlugin and interactionPlugin (if not needed)
  initialView: 'dayGridMonth',
  headerToolbar: {
    left: 'prev,next today',
    center: 'title',
    right: 'dayGridMonth,listWeek', // Only month and list
  },
  height: 'auto',
  expandRows: true,
  selectable: false,
  nowIndicator: true,
  eventTimeFormat: { hour: 'numeric', minute: '2-digit', meridiem: 'short' },
  displayEventEnd: true,
  dayMaxEvents: 3,
  moreLinkClick: 'popover',
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

/* ---------- Lifecycle ---------- */
onMounted(async () => {
  await loadBabyInfo()
  await loadEntries()
})
watch(babyId, async () => {
  await loadBabyInfo()
  await loadEntries()
})
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
