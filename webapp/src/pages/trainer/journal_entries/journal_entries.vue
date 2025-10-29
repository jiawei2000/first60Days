<template>
  <VCard title="All Journal Entries">
    <VCardText>
      <VDataTable
        :headers="headers"
        :items="journalEntries"
        :items-per-page="10"
        :loading="loading"
        loading-text="Loading journal entries..."
      />
    </VCardText>
  </VCard>

  <VSnackbar v-model="isSnackBarVisible" timeout="5000">
    {{ snackBarMessage }}
    <template #actions>
      <VBtn color="error" @click="isSnackBarVisible = false">Close</VBtn>
    </template>
  </VSnackbar>
</template>

<script setup>
import { ref, onMounted } from 'vue'

definePage({
  meta: {
    trainerOnly: true,
  },
})

const journalEntries = ref([])
const loading = ref(false)
const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

const headers = [
  { title: 'Baby Name', key: 'babyName' },
  { title: 'Cycle No', key: 'cycleNo' },
  { title: 'Awake Time', key: 'awakeTime' },
  { title: 'Start Feed', key: 'startFeedTime' },
  { title: 'Start Play', key: 'startPlayTime' },
  { title: 'Start Sleep', key: 'startSleepTime' },
  { title: 'Feed Type', key: 'feedType' },
  { title: 'Stool', key: 'hasStool' },
  { title: 'Urine', key: 'hasUrine' },
  { title: 'Remarks', key: 'remarks' },
]

onMounted(() => {
  loadAllJournalEntries()
})

async function loadAllJournalEntries() {
  loading.value = true

  try {
    const userRes = await $api('trainers/users', {
      method: 'GET',
      onResponseError({ response }) {
        throw new Error('Failed to fetch users')
      },
    })

    const users = userRes.users || []
    const allEntries = []

    for (const user of users) {
      const userId = user.id

      const babyRes = await $api(`trainers/users/${userId}/babies`, {
        method: 'GET',
        onResponseError({ response }) {
          throw new Error(`Failed to fetch babies for user ${user.name}`)
        },
      })

      const babies = babyRes.babies || []

for (const baby of babies) {
  const babyId = baby.id

  let entries = []

  try {
    const journalRes = await $api(`journalEntries/${babyId}`, {
      method: 'GET',
    })

    entries = Array.isArray(journalRes) ? journalRes : []
  } catch (error) {
    console.warn(`No journal entries for baby "${baby.name}" (${babyId})`)
    continue
  }

  for (const entry of entries) {
    allEntries.push({
      babyName: baby.name,
      cycleNo: entry.cycleNo || 'NA',
      awakeTime: formatSecondsToDateString(entry.awakeTime && entry.awakeTime._seconds),
      startFeedTime: formatSecondsToDateString(entry.startFeedTime && entry.startFeedTime._seconds),
      startPlayTime: formatSecondsToDateString(entry.startPlayTime && entry.startPlayTime._seconds),
      startSleepTime: formatSecondsToDateString(entry.startSleepTime && entry.startSleepTime._seconds),
      feedType: formatFeedType(entry.feedType),
      hasStool: entry.hasStool ? 'Yes' : 'No',
      hasUrine: entry.hasUrine ? 'Yes' : 'No',
      remarks: entry.remarks || '',
    })
  }
}

    }

    journalEntries.value = allEntries
  } catch (err) {
    snackBarMessage.value = err.message || 'Something went wrong'
    isSnackBarVisible.value = true
  } finally {
    loading.value = false
  }
}

function formatFeedType(feedType) {
  if (!Array.isArray(feedType) || feedType.length === 0) return 'NA'
  return feedType.map(f => `${f.type}: ${f.value}${f.unit}`).join(', ')
}
</script>
