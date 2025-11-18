<template>
  <VCard title="Babies Managed by You">
    <VCardText>
      <VDataTable
        :headers="headers"
        :items="trainerBabies"
        :items-per-page="10"
        :no-data-text="loading ? 'Loading babies...' : 'No babies found'"
        @click:row="goToBabyAssistant"
        class="cursor-pointer"
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
import { useRouter } from 'vue-router'

definePage({
  meta: { trainerOnly: true },
})

const router = useRouter()

const trainerBabies = ref([])
const loading = ref(false)
const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

// Table columns
const headers = [
  { title: 'Baby Name', key: 'name' },
  { title: 'Gender', key: 'gender' },
  { title: 'Date of Birth', key: 'dob' },
  { title: 'Parent Name', key: 'parentName' },
  { title: 'Parent Email', key: 'parentEmail' },
]

onMounted(() => {
  loadTrainerBabies()
})

async function loadTrainerBabies() {
  loading.value = true

  try {
    const userRes = await $api('trainers/users', {
      method: 'GET',
      onResponseError() {
        throw new Error('Failed to fetch users')
      },
    })

    const users = userRes.users || []
    const babiesList = []

    for (const user of users) {
      const userId = user.id

      const babyRes = await $api(`trainers/users/${userId}/babies`, {
        method: 'GET',
        onResponseError() {
          throw new Error(`Failed to fetch babies for user ${user.name}`)
        },
      })

      const babies = babyRes.babies || []

      for (const baby of babies) {
        babiesList.push({
          id: baby.id,  // REQUIRED for assistant page
          name: baby.name,
          gender: baby.gender || 'N/A',
          dob: formatSecondsToDateString(baby.dob?._seconds),
          parentName: user.name || 'N/A',
          parentEmail: user.email || 'N/A',
        })
      }
    }

    trainerBabies.value = babiesList
  } catch (err) {
    snackBarMessage.value = err.message || 'Something went wrong'
    isSnackBarVisible.value = true
  } finally {
    loading.value = false
  }
}

// When user clicks a row → navigate to AI Assistant
function goToBabyAssistant(event, row) {
  const baby = row.item
  if (!baby.id) {
    snackBarMessage.value = "Error: Baby has no ID"
    isSnackBarVisible.value = true
    return
  }

  router.push(`/trainer/baby_assistant/${baby.id}`)
}

// Format timestamp from Firestore seconds
function formatSecondsToDateString(seconds) {
  if (!seconds) return 'N/A'
  const date = new Date(seconds * 1000)
  return date.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}
</script>

<style scoped>
.cursor-pointer tr {
  cursor: pointer;
}
</style>
