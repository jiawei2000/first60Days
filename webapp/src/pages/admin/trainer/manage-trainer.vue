<template>
  <VCard title="Manage Trainers">
    <VCardText>
      <!-- 🔍 Search Bar -->
      <VRow>
        <VCol>
          <VTextField
            v-model="search"
            placeholder="Try: 'Show trainers created in 2025'"
            append-inner-icon="bx-search"
            @keyup.enter="performSearch"
          />
        </VCol>
        <VCol class="d-flex justify-end">
          <VBtn color="secondary" class="mr-2" @click="clearSearch">Clear</VBtn>
          <VBtn color="primary" @click="performSearch">Search</VBtn>
          <VBtn
            color="success"
            class="ml-2"
            @click="$router.push('/admin/trainer/create-trainer')"
          >
            Create New Trainer
          </VBtn>
        </VCol>
      </VRow>

      <VSpacer class="my-6" />

      <!-- 🕒 Loading Spinner -->
      <div v-if="loading" class="text-center py-8">
        <VProgressCircular indeterminate color="primary" size="48" />
        <div class="text-medium-emphasis mt-3">Loading trainers...</div>
      </div>

      <!-- 📋 Data Table -->
      <VDataTable
        v-else
        :headers="headers"
        :items="data"
        :items-per-page="10"
        class="elevation-1"
      />

      <!-- ⚠️ Empty State -->
      <div
        v-if="!loading && !data.length"
        class="text-center text-medium-emphasis py-4"
      >
        No trainers found. Try a different query.
      </div>
    </VCardText>
  </VCard>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

definePage({
  meta: { adminOnly: true },
})

const router = useRouter()
const search = ref('')
const data = ref([])
const loading = ref(false)

const headers = [
  { title: 'Username', key: 'username' },
  { title: 'Name', key: 'name' },
  { title: 'Email', key: 'email' },
  { title: 'Created At', key: 'createdAt' },
  { title: 'Last Login', key: 'lastLoginAt' },
]

// ----------------------
// 🔹 On mount: load all trainers normally
// ----------------------
onMounted(() => {
  getTrainers()
})

// 🔹 Fetch all trainers (default load)
async function getTrainers() {
  try {
    loading.value = true
    const res = await $api('admins/trainers', {
      method: 'GET',
      onResponseError({ response }) {
        console.error(response._data?.error || 'API error')
      },
    })

    data.value = res.trainers.map((trainer) => ({
      id: trainer.id,
      username: trainer.username,
      name: trainer.name,
      email: trainer.email,
      phoneNo: trainer.phoneNo || 'N/A',
      createdAt: trainer.createdAt
        ? formatSecondsToDateString(trainer.createdAt._seconds)
        : 'N/A',
      lastLoginAt: trainer.lastLoginAt
        ? formatSecondsToDateString(trainer.lastLoginAt._seconds)
        : 'N/A',
    }))
  } catch (err) {
    console.error('❌ Failed to fetch trainers:', err)
  } finally {
    loading.value = false
  }
}

// ----------------------
// 🧠 Perform AI search (assistant/query)
// ----------------------
async function performSearch() {
  if (!search.value.trim()) {
    await getTrainers()
    return
  }

  try {
    loading.value = true
    data.value = []

    const res = await $api('assistant/trainers/query', {
      method: 'POST',
      body: { question: search.value },
      onResponseError({ response }) {
        throw new Error(response._data?.error || 'AI query failed')
      },
    })

    if (res?.results?.length) {
      data.value = res.results.map((trainer) => ({
        id: trainer.id,
        username: trainer.username || '-',
        name: trainer.name || '-',
        email: trainer.email || '-',
        phoneNo: trainer.phoneNo || '-',
        createdAt: trainer.createdAt
          ? formatSecondsToDateString(trainer.createdAt._seconds)
          : '-',
        lastLoginAt: trainer.lastLoginAt
          ? formatSecondsToDateString(trainer.lastLoginAt._seconds)
          : '-',
      }))
    } else {
      data.value = []
    }
  } catch (err) {
    console.error('❌ AI search failed:', err.message)
  } finally {
    loading.value = false
  }
}

// ----------------------
// 🧹 Clear search
// ----------------------
function clearSearch() {
  search.value = ''
  getTrainers()
}

// 🔸 Navigate to edit page
function editTrainer(trainer) {
  router.push(`/admin/trainer/edit-trainer/${trainer.id}`)
}
</script>

<style scoped>
.text-truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
