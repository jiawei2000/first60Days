<template>
  <div class="pa-4">
    <VCard class="pa-2">
      <VCardTitle class="d-flex align-center justify-space-between pr-4">
        <div>
          <div class="text-h6">Baby Schedule</div>
          <div class="text-caption text-medium-emphasis">Baby ID: {{ babyId }}</div>
        </div>
        <div class="d-flex align-center gap-2">
          <VBtn color="primary" prepend-icon="bx-plus" @click="openCreate">Add Event</VBtn>
        </div>
      </VCardTitle>
      <VCardText>
        <div class="d-flex align-center gap-2 mb-3 filters">
          <VChip
            filter
            :color="filters.feed ? typeColors.feed : undefined"
            :variant="filters.feed ? 'flat' : 'tonal'"
            @click="filters.feed = !filters.feed"
          >🍼 Feed</VChip>
          <VChip
            filter
            :color="filters.play ? typeColors.play : undefined"
            :variant="filters.play ? 'flat' : 'tonal'"
            @click="filters.play = !filters.play"
          >🎈 Play</VChip>
          <VChip
            filter
            :color="filters.awake ? typeColors.awake : undefined"
            :variant="filters.awake ? 'flat' : 'tonal'"
            @click="filters.awake = !filters.awake"
          >🌤️ Awake</VChip>
          <VChip
            filter
            :color="filters.sleep ? typeColors.sleep : undefined"
            :variant="filters.sleep ? 'flat' : 'tonal'"
            @click="filters.sleep = !filters.sleep"
          >😴 Sleep</VChip>
        </div>
        <FullCalendar ref="calendarRef" :options="calendarOptions" />
        <div v-if="currentView === 'dayGridMonth'" class="mt-4">
          <div class="text-subtitle-1 mb-2">{{ formatSelectedDate(selectedDate) }}</div>
          <div v-if="dayEvents.length === 0" class="text-medium-emphasis">No entries to display</div>
          <div v-else class="event-list--mobile">
            <div v-for="ev in dayEvents" :key="ev.id" class="event-row">
              <span class="dot" :style="{ backgroundColor: typeColors[ev.extendedProps?.type] || '#888' }"></span>
              <span class="time">{{ formatEventTime(ev) }}</span>
              <span class="title">{{ ev.extendedProps?.icon || '' }} {{ ev.title }}</span>
            </div>
          </div>
        </div>
      </VCardText>
    </VCard>

    <!-- Add/Edit Event Drawer (demo-like) -->
    <VNavigationDrawer v-model="isDrawerOpen" location="end" temporary width="420">
      <VToolbar density="comfortable" :title="selectedEvent?.id ? 'Edit Event' : 'Add Event'" />
      <div class="pa-4">
        <VForm class="d-flex flex-column gap-4">
          <AppTextField v-model="form.title" label="Title" />
          <VSelect v-model="form.label" :items="labels" item-title="text" item-value="value" label="Label" />
          <AppDateTimePicker v-model="form.start" label="Start date" :config="{ enableTime: true, dateFormat: 'Y-m-d H:i' }" />
          <AppDateTimePicker v-model="form.end" label="End date (optional)" :config="{ enableTime: true, dateFormat: 'Y-m-d H:i' }" />
          <VSwitch v-model="form.allDay" label="All day" />
          <VDivider />
          <div class="d-flex gap-2">
            <VBtn color="primary" @click="saveEvent">Save</VBtn>
            <VBtn variant="tonal" @click="isDrawerOpen = false">Cancel</VBtn>
            <VSpacer />
            <VBtn color="error" variant="tonal" v-if="selectedEvent?.id" @click="removeEvent">Delete</VBtn>
          </div>
        </VForm>
      </div>
    </VNavigationDrawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import AppTextField from '@core/components/app-form-elements/AppTextField.vue'
import AppDateTimePicker from '@core/components/app-form-elements/AppDateTimePicker.vue'
import { useRoute } from 'vue-router'
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
import timeGridPlugin from '@fullcalendar/timegrid'
import interactionPlugin from '@fullcalendar/interaction'
import listPlugin from '@fullcalendar/list'

// Styles: FullCalendar v6 packages no longer export CSS paths
// consumable by Vite's ESM resolver. Import our template's
// FullCalendar SCSS instead to avoid missing specifier errors
// and keep consistent styling.
import '@core/scss/template/libs/full-calendar.scss'

definePage({
  meta: { trainerOnly: true },
})

const route = useRoute()
const babyId = computed(() => route.params.id)

const calendarRef = ref(null)
const isDrawerOpen = ref(false)
const selectedEvent = ref(null)
const labels = [
  { text: 'Personal', value: 'personal' },
  { text: 'Business', value: 'business' },
  { text: 'Family', value: 'family' },
  { text: 'Other', value: 'other' },
]
const form = ref({ title: '', label: 'other', start: '', end: '', allDay: false })

function openCreate() {
  selectedEvent.value = null
  form.value = { title: '', label: 'other', start: '', end: '', allDay: false }
  isDrawerOpen.value = true
}

// Events populated from backend journal entries (base mapped)
const events = ref([])
// Current view type so we can tune rendering per view
const currentView = ref('dayGridMonth')
const selectedDate = ref(new Date())

// Quick filter toggles by type
// Checked = shown; default hides Awake to reduce clutter in week/day
const filters = ref({ feed: true, play: true, awake: false, sleep: true })

function tsToIso(ts) {
  // firestore-like timestamp: { _seconds }
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

function addHours(iso, hours) {
  const d = new Date(iso)
  d.setHours(d.getHours() + (hours || 0))
  return d.toISOString()
}

function minutesFromFeedTypes(feedType) {
  if (!Array.isArray(feedType)) return 15 // sensible default
  let total = 0
  for (const f of feedType) {
    if (!f) continue
    if (String(f.unit).toLowerCase() === 'minutes' && typeof f.value === 'number') total += f.value
  }
  return total || 15
}

// Distinct palette used by chips and events
const typeColors = { feed: '#29B6F6', play: '#7E57C2', sleep: '#26A69A', awake: '#FFB74D' }

async function loadEntries() {
  try {
    const id = babyId.value
    if (!id) return
    const res = await $api(`journalEntries/${id}`, { method: 'GET' })
    const list = Array.isArray(res) ? res : []
    const mapped = []

    for (const e of list) {
      const cycle = e.cycleNo ? ` (Cycle ${e.cycleNo})` : ''

      const awakeStart = tsToIso(e.awakeTime)
      const feedStart = tsToIso(e.startFeedTime)
      const playStart = tsToIso(e.startPlayTime)
      const sleepStart = tsToIso(e.startSleepTime)

      // Sleep band (background)
      if (sleepStart) {
        const durationHours = typeof e.sleepDuration === 'number' ? e.sleepDuration : null
        const sleepEnd = durationHours ? addHours(sleepStart, durationHours) : null
        mapped.push({
          id: `${e.id}-sleep`,
          title: `Sleep${cycle}`.trim(),
          start: sleepStart,
          end: sleepEnd || addHours(sleepStart, 1),
          display: 'background',
          backgroundColor: typeColors.sleep,
          borderColor: typeColors.sleep,
          extendedProps: { type: 'sleep', icon: '😴' },
        })
      }

      // Optional Awake band (background). We still build it, but
      // default filters hide it to keep week/day clean.
      if (awakeStart) {
        const awakeEnd = sleepStart || addHours(awakeStart, 2)
        mapped.push({
          id: `${e.id}-awake`,
          title: `Awake${cycle}`.trim(),
          start: awakeStart,
          end: awakeEnd,
          display: 'background',
          backgroundColor: typeColors.awake,
          borderColor: typeColors.awake,
          extendedProps: { type: 'awake', icon: '🌤️' },
        })
      }

      // Feed pill
      if (feedStart) {
        const mins = minutesFromFeedTypes(e.feedType)
        mapped.push({
          id: `${e.id}-feed`,
          title: `Feed${cycle}`.trim(),
          start: feedStart,
          end: addMinutes(feedStart, mins),
          backgroundColor: typeColors.feed,
          borderColor: typeColors.feed,
          textColor: '#fff',
          extendedProps: { type: 'feed', icon: '🍼', raw: e },
        })
      }

      // Play pill (default 30m if no end provided)
      if (playStart) {
        mapped.push({
          id: `${e.id}-play`,
          title: `Play${cycle}`.trim(),
          start: playStart,
          end: addMinutes(playStart, 30),
          backgroundColor: typeColors.play,
          borderColor: typeColors.play,
          textColor: '#fff',
          extendedProps: { type: 'play', icon: '🎈', raw: e },
        })
      }
    }

    events.value = mapped

    // If the selected day has no events, default to the first event day
    const hasForSelected = mapped.some(ev => ymd(ev.start) === ymd(selectedDate.value))
    if (!hasForSelected && mapped.length) {
      selectedDate.value = new Date(mapped[0].start)
    }

    // Rerender month cells so markers appear after async load
    try {
      calendarRef.value?.getApi()?.render()
    } catch {}
  } catch (err) {
    console.error('Failed to load journal entries for calendar', err)
  }
}

const calendarOptions = ref({
  plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin, listPlugin],
  initialView: 'dayGridMonth',
  headerToolbar: {
    left: 'prev,next today',
    center: 'title',
    right: 'dayGridMonth,timeGridWeek,timeGridDay,listWeek',
  },
  height: 'auto',
  expandRows: true,
  selectable: true,
  selectMirror: true,
  nowIndicator: true,
  eventTimeFormat: { hour: 'numeric', minute: '2-digit', meridiem: 'short' },
  displayEventEnd: true,
  dayMaxEvents: 3,
  moreLinkClick: 'popover',
  events: computed(() => eventsForView.value.filter(ev => !!filters.value[ev.extendedProps?.type])),
  views: {
    dayGridMonth: { dayMaxEventRows: 3 },
    timeGridWeek: {
      slotMinTime: '05:00:00',
      slotMaxTime: '22:00:00',
      slotDuration: '00:10:00',
      snapDuration: '00:05:00',
      slotEventOverlap: false,
      eventMaxStack: 3,
    },
    timeGridDay: {
      slotMinTime: '05:00:00',
      slotMaxTime: '22:00:00',
      slotDuration: '00:10:00',
      snapDuration: '00:05:00',
      slotEventOverlap: false,
      eventMaxStack: 4,
    },
    listWeek: { showNonCurrentDates: false },
  },
  datesSet(arg) {
    currentView.value = arg.view.type
  },
  dateClick(info) {
    if (currentView.value === 'dayGridMonth') selectedDate.value = info.date
  },
  dayCellDidMount() {},
  // Compact visual pills for non-background events
  eventContent(arg) {
    // Month view: render compact pill with time + icon + short title
    if (currentView.value === 'dayGridMonth') {
      if (arg.event.display === 'background') return { domNodes: [] }
      const icon = arg.event.extendedProps?.icon || ''
      const time = arg.timeText ? `${arg.timeText} ` : ''
      const title = arg.event.title?.split('(')[0]?.trim() || arg.event.title
      const el = document.createElement('div')
      el.className = 'fc-pill fc-pill--month'
      el.innerText = `${time}${icon} ${title}`
      return { domNodes: [el] }
    }
    if (arg.event.display === 'background') return { domNodes: [] }
    const icon = arg.event.extendedProps?.icon || ''
    const time = arg.timeText ? `${arg.timeText} ` : ''
    const title = arg.event.title?.split('(')[0]?.trim() || arg.event.title
    const container = document.createElement('div')
    container.className = 'fc-pill'
    container.innerText = `${time}${icon} ${title}`
    return { domNodes: [container] }
  },
})

// For timeGrid views, convert Sleep/Awake background bands into short markers
// so Week/Day look similar to Month pills (standardised and compact).
const eventsForView = computed(() => {
  const isTime = currentView.value === 'timeGridWeek' || currentView.value === 'timeGridDay'
  if (currentView.value === 'dayGridMonth') {
    // Month view: render all types as short, colored pills on their start time
    return events.value.map(ev => {
      const type = ev.extendedProps?.type
      return {
        ...ev,
        display: 'block',
        backgroundColor: typeColors[type] || ev.backgroundColor,
        borderColor: typeColors[type] || ev.borderColor,
        textColor: '#fff',
        end: ev.end || addMinutes(ev.start, 1),
      }
    })
  }
  if (!isTime) return events.value
  const out = []
  for (const ev of events.value) {
    const type = ev.extendedProps?.type
    if (type === 'sleep' || type === 'awake') {
      out.push({
        ...ev,
        display: 'block',
        backgroundColor: typeColors[type],
        borderColor: typeColors[type],
        textColor: '#fff',
        // render as a short 10-minute marker at start for readability
        end: addMinutes(ev.start, 10),
      })
    } else {
      out.push(ev)
    }
  }
  return out
})

// Helpers for month markers + day list
function ymd(d) {
  const dt = new Date(d)
  return `${dt.getFullYear()}-${String(dt.getMonth()+1).padStart(2,'0')}-${String(dt.getDate()).padStart(2,'0')}`
}

// no monthSummary; using in-cell compact events

const dayEvents = computed(() => {
  const key = ymd(selectedDate.value)
  return eventsForView.value
    .filter(ev => filters.value[ev.extendedProps?.type])
    .filter(ev => ymd(ev.start) === key)
    .sort((a,b) => new Date(a.start) - new Date(b.start))
})

function formatSelectedDate(d) {
  const dt = new Date(d)
  return dt.toLocaleDateString(undefined, { weekday:'long', year:'numeric', month:'long', day:'numeric' })
}

function formatEventTime(ev) {
  const s = new Date(ev.start)
  const e = ev.end ? new Date(ev.end) : null
  const opts = { hour:'numeric', minute:'2-digit' }
  const st = s.toLocaleTimeString([], opts).replace(' AM','am').replace(' PM','pm')
  const et = e ? e.toLocaleTimeString([], opts).replace(' AM','am').replace(' PM','pm') : null
  return e ? `${st} - ${et}` : `${st}`
}

onMounted(loadEntries)
watch(babyId, loadEntries)
watch([events, filters, currentView], async () => {
  if (currentView.value === 'dayGridMonth') {
    await nextTick()
    try { calendarRef.value?.getApi()?.render() } catch {}
  }
})

function saveEvent() {
  const api = calendarRef.value?.getApi()
  if (!api) return
  if (selectedEvent.value?.id) {
    // Update existing
    selectedEvent.value.setProp('title', form.value.title || 'Untitled')
    selectedEvent.value.setExtendedProp('label', form.value.label)
    if (form.value.allDay) selectedEvent.value.setAllDay(true)
    if (form.value.start) selectedEvent.value.setStart(form.value.start)
    if (form.value.end) selectedEvent.value.setEnd(form.value.end || null)
  } else {
    // Create new
    api.addEvent({
      id: String(Math.random()),
      title: form.value.title || 'Untitled',
      start: form.value.start || new Date().toISOString(),
      end: form.value.end || undefined,
      allDay: form.value.allDay,
      extendedProps: { label: form.value.label },
    })
  }
  isDrawerOpen.value = false
}

function removeEvent() {
  if (!selectedEvent.value) return
  selectedEvent.value.remove()
  isDrawerOpen.value = false
}
</script>

<style scoped>
.fc { /* ensure calendar respects card and page width */ }

/* Compact event pill for timed events */
.fc .fc-daygrid-event,
.fc .fc-timegrid-event {
  border-radius: 8px;
  padding: 0;
  overflow: hidden;
  border: 0 !important; /* avoid 1px borders causing misalignment */
}
.fc .fc-timegrid-event .fc-event-main {
  padding: 2px 6px;
  font-size: 12px;
  line-height: 16px;
}
/* keep daygrid time; we render our own content */

/* Background state bands (sleep/awake) subtler */
.fc .fc-bg-event { opacity: 0.08; }

.fc-pill {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.fc-pill--month {
  padding: 1px 4px;
  font-size: 11px;
  line-height: 14px;
}

.filters .v-chip { cursor: pointer; }

/* Mobile-like list under month view */
.event-row { display: flex; align-items: center; gap: 8px; }
.event-row .dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; }
.event-row .time { color: rgba(255,255,255,0.7); width: 140px; white-space: nowrap; }
.event-row .title { font-weight: 500; }
.event-list--mobile { display: flex; flex-direction: column; gap: 6px; }

</style>
