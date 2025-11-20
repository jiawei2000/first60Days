<template>
  <VContainer>

    <!-- MAIN CARD -->
    <VCard>
      <VCardTitle class="text-h5 font-weight-bold">
        Admin Dashboard
      </VCardTitle>

      <VCardText>

        <!-- LOADING -->
        <div v-if="loading" class="text-medium-emphasis">
          Loading dashboard data...
        </div>

        <!-- ERROR -->
        <div v-else-if="error" class="text-error">
          Failed to load dashboard data: {{ error }}
        </div>

        <!-- CONTENT -->
        <div v-else>

          <!-- METRICS ROW -->
          <VRow class="mb-6">
            <VCol cols="12" md="4">
              <VCard class="pa-4 d-flex align-center" elevation="1">
                <VAvatar size="48" class="me-4" color="primary" variant="tonal">
                  <VIcon icon="bx-user-voice" />
                </VAvatar>
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Total Trainers</p>
                  <h3 class="text-h5 font-weight-bold mb-0">
                    {{ dashboardData.totalTrainers }}
                  </h3>
                </div>
              </VCard>
            </VCol>

            <VCol cols="12" md="4">
              <VCard class="pa-4 d-flex align-center" elevation="1">
                <VAvatar size="48" class="me-4" color="info" variant="tonal">
                  <VIcon icon="bx-user" />
                </VAvatar>
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Total Users</p>
                  <h3 class="text-h5 font-weight-bold mb-0">
                    {{ dashboardData.totalUsers }}
                  </h3>
                </div>
              </VCard>
            </VCol>

            <VCol cols="12" md="4">
              <VCard class="pa-4 d-flex align-center" elevation="1">
                <VAvatar size="48" class="me-4" color="success" variant="tonal">
                  <VIcon icon="bx-baby" />
                </VAvatar>
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Total Babies</p>
                  <h3 class="text-h5 font-weight-bold mb-0">
                    {{ dashboardData.totalBabies }}
                  </h3>
                </div>
              </VCard>
            </VCol>
          </VRow>

          <!-- LATEST USERS TABLE -->
          <VCard>
            <VCardTitle class="text-subtitle-1 font-weight-bold">
              Latest Users
            </VCardTitle>

            <VCardText>
              <VDataTable
                :headers="headers"
                :items="latestUsers"
                :items-per-page="10"
              >
                <!-- CREATED AT -->
                <template #item.createdAt="{ item }">
                  <span>
                    {{ item.createdAt }}
                  </span>
                </template>
              </VDataTable>
            </VCardText>
          </VCard>

        </div>
      </VCardText>
    </VCard>

    <!-- SNACKBAR -->
    <VSnackbar v-model="isSnackBarVisible" timeout="5000">
      {{ snackBarMessage }}
      <template #actions>
        <VBtn color="error" @click="isSnackBarVisible = false">Close</VBtn>
      </template>
    </VSnackbar>

  </VContainer>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { formatSecondsToDateString } from '@/utils/dateFormatter'

definePage({
  meta: { adminOnly: true }
})

const loading = ref(true)
const error = ref(null)

const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

const dashboardData = ref({
  totalUsers: 0,
  totalTrainers: 0,
  totalBabies: 0,
})

const latestUsers = ref([])

const headers = [
  { title: "Name", key: "name" },
  { title: "Email", key: "email" },
  { title: "Created At", key: "createdAt" },
]

async function fetchDashboardData() {
  loading.value = true
  error.value = null

  try {
    const [dashboardRes, usersRes] = await Promise.all([
      $api('admins/dashboard'),
      $api('admins/users'),
    ])

    dashboardData.value = dashboardRes.data || dashboardData.value

    const users = usersRes.users || []

    latestUsers.value = users
      .map(user => ({
        id: user.id,
        name: user.name || user.username,
        email: user.email,
        createdAtSeconds: user.createdAt?._seconds ?? null,
      }))
      .filter(u => u.createdAtSeconds !== null)
      .sort((a, b) => b.createdAtSeconds - a.createdAtSeconds)
      .slice(0, 3)
      .map(u => ({
        ...u,
        createdAt: formatSecondsToDateString(u.createdAtSeconds)
      }))

  } catch (err) {
    console.error(err)
    error.value = err?.message || 'Unknown error'
  } finally {
    loading.value = false
  }
}

onMounted(fetchDashboardData)
</script>
