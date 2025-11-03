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
        <FullCalendar ref="calendarRef" :options="calendarOptions" />
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
import { ref, computed, onMounted, watch } from 'vue'
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

// Events populated from backend journal entries
const events = ref([])

function tsToIso(ts) {
  if (!ts || typeof ts._seconds !== 'number') return null
  return new Date(ts._seconds * 1000).toISOString()
}

async function loadEntries() {
  try {
    const id = babyId.value
    if (!id) return
    const res = await $api(`journalEntries/${id}`, { method: 'GET' })
    const list = Array.isArray(res) ? res : []
    const mapped = []
    for (const e of list) {
      const cycle = e.cycleNo ? ` (Cycle ${e.cycleNo})` : ''
      if (e.awakeTime && e.awakeTime._seconds) {
        mapped.push({ id: `${e.id}-awake`, title: `Awake${cycle}`.trim(), start: tsToIso(e.awakeTime) })
      }
      if (e.startFeedTime && e.startFeedTime._seconds) {
        mapped.push({ id: `${e.id}-feed`, title: `Feed${cycle}`.trim(), start: tsToIso(e.startFeedTime) })
      }
      if (e.startPlayTime && e.startPlayTime._seconds) {
        mapped.push({ id: `${e.id}-play`, title: `Play${cycle}`.trim(), start: tsToIso(e.startPlayTime) })
      }
      if (e.startSleepTime && e.startSleepTime._seconds) {
        const start = tsToIso(e.startSleepTime)
        const end = typeof e.sleepDuration === 'number' && e.sleepDuration > 0
          ? new Date(new Date(start).getTime() + e.sleepDuration * 60 * 1000).toISOString()
          : undefined
        mapped.push({ id: `${e.id}-sleep`, title: `Sleep${cycle}`.trim(), start, end })
      }
    }
    events.value = mapped
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
  selectable: true,
  selectMirror: true,
  nowIndicator: true,
  events,
  select(info) {
    selectedEvent.value = null
    form.value = {
      title: '',
      label: 'other',
      start: info.startStr,
      end: info.endStr || '',
      allDay: info.allDay || false,
    }
    isDrawerOpen.value = true
  },
  eventClick(info) {
    selectedEvent.value = info.event
    form.value = {
      title: info.event.title,
      label: info.event.extendedProps?.label || 'other',
      start: info.event.startStr || '',
      end: info.event.endStr || '',
      allDay: info.event.allDay || false,
    }
    isDrawerOpen.value = true
  },
  views: {
    timeGridWeek: { slotMinTime: '06:00:00', slotMaxTime: '22:00:00' },
  },
})

onMounted(loadEntries)
watch(babyId, loadEntries)

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
</style>
