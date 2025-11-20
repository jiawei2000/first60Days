<template>
    <div class="pa-4">
        <!-- ---------------- CALENDAR CARD ---------------- -->
        <VCard :title="`Baby Schedule for ${babyName || '...'}`">
            <!-- Date Picker -->
            <VCardText>
                <VRow>
                    <VCol class="">
                        <VTextField v-model="question" label="Ask a question about this baby's health"
                            placeholder="e.g. Why is the baby crying so much?" clearable />
                    </VCol>
                    <!-- Buttons Row -->
                    <VCol cols="auto">
                        <VBtn color="primary" :loading="loading" @click="askAI">
                            Ask AI
                        </VBtn>
                    </VCol>
                    <!-- CLEAR BUTTON (only shows when answer exists) -->
                    <VCol cols="auto">
                        <VBtn color="grey" variant="tonal" @click="clearAI">
                            Clear
                        </VBtn>
                    </VCol>

                    <VCol class="d-flex justify-end">
                        <VMenu v-model="datePickerMenu" :close-on-content-click="false" location="bottom end">
                            <template #activator="{ props }">
                                <VBtn color="primary" v-bind="props" variant="flat" size="small">📅 Jump to Date</VBtn>
                            </template>
                            <VCard class="pa-2">
                                <VDatePicker v-model="selectedDate" show-adjacent-months color="primary"
                                    @update:modelValue="onDatePicked" />
                            </VCard>
                        </VMenu>
                        <!-- Switch Page Button -->
                        <VBtn variant="tonal" color="primary" size="small" class="ml-3" @click="goToOtherPage">
                            🔄 Switch to Statistics
                        </VBtn>
                    </VCol>
                </VRow>
            </VCardText>


            <VAlert v-if="answer" type="info" variant="outlined" class="mt-4">
                <strong>AI Response:</strong><br />
                {{ answer }}
            </VAlert>

            <VCardText>
                <FullCalendar ref="calendarRef" :options="calendarOptions" />
            </VCardText>
        </VCard>

        <!-- Entry Drawer (unchanged) -->
        <VNavigationDrawer v-model="isDrawerOpen" location="end" temporary width="420">
            <VToolbar density="comfortable" title="Entry Details" />
            <div class="pa-4 entry-drawer-content">
                <div v-if="entryDetails">
                    <div class="text-subtitle-1 mb-3">
                        {{ formatDateTime(entryDetails.awakeTime) }}
                    </div>

                    <VList density="compact" lines="two">
                        <VListItem>
                            <VListItemTitle>📘 Entry # {{ safe(entryDetails.entryNo) }}</VListItemTitle>
                        </VListItem>

                        <VDivider class="mb-1" />

                        <VListItem>
                            <VListItemTitle>🕓 Wake Up Time</VListItemTitle>
                            <VListItemSubtitle>{{ formatDateTime(entryDetails.awakeTime) }}</VListItemSubtitle>
                        </VListItem>

                        <VListItem>
                            <VListItemTitle>🍼 Start of Feed Time</VListItemTitle>
                            <VListItemSubtitle>{{ formatDateTime(entryDetails.startFeedTime) }}</VListItemSubtitle>
                        </VListItem>

                        <VListItem v-if="prettyFeedTypes(entryDetails.feedType)">
                            <VListItemTitle>🍼 Feed Details</VListItemTitle>
                            <VListItemSubtitle>{{ prettyFeedTypes(entryDetails.feedType) }}</VListItemSubtitle>
                        </VListItem>

                        <VListItem>
                            <VListItemTitle>🎈 Start of Play Time</VListItemTitle>
                            <VListItemSubtitle>{{ formatDateTime(entryDetails.startPlayTime) }}</VListItemSubtitle>
                        </VListItem>

                        <VListItem>
                            <VListItemTitle>😴 Start of Sleep Time</VListItemTitle>
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

        <!-- Snackbar for AI -->
        <VSnackbar v-model="isSnackBarVisible" timeout="5000">
            {{ snackBarMessage }}
            <template #actions>
                <VBtn color="error" @click="isSnackBarVisible = false">Close</VBtn>
            </template>
        </VSnackbar>
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
const question = ref("")
const answer = ref("")
const loading = ref(false)
const isSnackBarVisible = ref(false)
const snackBarMessage = ref("")

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
            // if name is formula change to Formula
            // if name is breastfeed_right change to Breastfeed (Right)
            // if name is breastfeed_left change to Breastfeed (Left)
            let displayName = ''
            if (name.toLowerCase() === 'formula') {
                displayName = 'Formula'
            } else if (name.toLowerCase() === 'breastfeed_right') {
                displayName = 'Breastfeed (Right)'
            } else if (name.toLowerCase() === 'breastfeed_left') {
                displayName = 'Breastfeed (Left)'
            } else {
                displayName = name.charAt(0).toUpperCase() + name.slice(1)
            }
            return [displayName, value && unit ? `${value} ${unit}` : ''].filter(Boolean).join(' • ')
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
    const used = new Set(['id', 'cycleNo', 'awakeTime', 'startFeedTime', 'startPlayTime', 'startSleepTime', 'sleepDuration', 'feedType', 'iso', 'timestamp', 'entryNo', 'dateKey'])
    const labelMap = {
        hasStool: '💩 Has the baby pooped?',
        hasUrine: '🚽 Has the baby peed?',
        remarks: '📝 Remarks',
        status: '📋 Entry Status',
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

async function askAI() {
    if (!question.value.trim()) {
        snackBarMessage.value = "Please enter a question."
        isSnackBarVisible.value = true
        return
    }

    loading.value = true
    answer.value = ""

    try {
        const res = await $api(`/assistant/babies/query/${babyId.value}`, {
            method: "POST",
            body: { question: question.value }
        })
        answer.value = res.answer
    } catch (err) {
        snackBarMessage.value = "Error fetching AI response."
        isSnackBarVisible.value = true
    } finally {
        loading.value = false
    }
}

function clearAI() {
    question.value = ""
    answer.value = ""
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
.entry-drawer-content {
  max-height: calc(100vh - 56px);
  overflow-y: auto;
}

@media (min-width: 600px) {
  .entry-drawer-content {
    max-height: calc(100vh - 64px);
  }
}
</style>

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
