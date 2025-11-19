<template>
  <VContainer>
    <VRow class="mb-4">
      <VCol cols="12">
        <h1 class="text-h4 font-weight-bold">Admin Dashboard</h1>
      </VCol>
    </VRow>

    <VRow v-if="loading">
      <VCol cols="12">
        <div class="text-medium-emphasis">Loading dashboard data...</div>
      </VCol>
    </VRow>

    <VRow v-else-if="error">
      <VCol cols="12">
        <div class="text-error">
          Failed to load dashboard data: {{ error }}
        </div>
      </VCol>
    </VRow>

    <VRow v-else>
      <VCol cols="12" md="4">
        <VCard
          class="pa-4 d-flex align-center"
          :class="$vuetify.theme.dark ? 'bg-surface' : 'bg-grey-lighten-5'"
        >
          <VAvatar size="48" class="me-4" color="primary" variant="tonal">
            <VIcon icon="bx-user-voice" />
          </VAvatar>
          <div>
            <p class="text-caption text-medium-emphasis mb-0">
              Total Trainers
            </p>
            <h3 class="text-h5 font-weight-bold mb-0">
              {{ dashboardData.totalTrainers }}
            </h3>
          </div>
        </VCard>
      </VCol>

      <VCol cols="12" md="4">
        <VCard
          class="pa-4 d-flex align-center"
          :class="$vuetify.theme.dark ? 'bg-surface' : 'bg-grey-lighten-4'"
        >
          <VAvatar size="48" class="me-4" color="info" variant="tonal">
            <VIcon icon="bx-user" />
          </VAvatar>
          <div>
            <p class="text-caption text-medium-emphasis mb-0">
              Total Users
            </p>
            <h3 class="text-h5 font-weight-bold mb-0">
              {{ dashboardData.totalUsers }}
            </h3>
          </div>
        </VCard>
      </VCol>

      <VCol cols="12" md="4">
        <VCard
          class="pa-4 d-flex align-center"
          :class="$vuetify.theme.dark ? 'bg-surface' : 'bg-grey-lighten-3'"
        >
          <VAvatar size="48" class="me-4" color="success" variant="tonal">
            <VIcon icon="bx-baby-carriage" />
          </VAvatar>
          <div>
            <p class="text-caption text-medium-emphasis mb-0">
              Total Babies
            </p>
            <h3 class="text-h5 font-weight-bold mb-0">
              {{ dashboardData.totalBabies }}
            </h3>
          </div>
        </VCard>
      </VCol>
    </VRow>

    <VRow
      v-if="!loading && !error"
      class="mt-8"
    >
      <VCol cols="12">
        <VCard>
          <VCardTitle class="text-subtitle-1 font-weight-bold">
            Latest Users
          </VCardTitle>
          <VCardText>
            <VTable density="compact">
              <thead>
                <tr>
                  <th class="text-left">
                    Name
                  </th>
                  <th class="text-left">
                    Email
                  </th>
                  <th class="text-left">
                    Created At
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="!latestUsers.length">
                  <td
                    colspan="3"
                    class="text-medium-emphasis text-center"
                  >
                    No users found.
                  </td>
                </tr>
                <tr
                  v-for="user in latestUsers"
                  :key="user.id"
                >
                  <td>{{ user.name || user.username }}</td>
                  <td>{{ user.email }}</td>
                  <td>{{ user.createdAt }}</td>
                </tr>
              </tbody>
            </VTable>
          </VCardText>
        </VCard>
      </VCol>
    </VRow>
  </VContainer>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { formatSecondsToDateString } from '@/utils/dateFormatter'

definePage({
  meta: {
    adminOnly: true,
  },
})

const loading = ref(true)
const error = ref(null)
const dashboardData = ref({
  totalUsers: 0,
  totalTrainers: 0,
  totalBabies: 0,
})
const latestUsers = ref([])

async function fetchDashboardData() {
  loading.value = true
  error.value = null
  try {
    const [dashboardRes, usersRes] = await Promise.all([
      $api('admins/dashboard'),
      $api('admins/users'),
    ])

    // Backend returns { success, message, data: { totalUsers, totalTrainers, totalBabies } }
    dashboardData.value = dashboardRes.data || dashboardData.value

    const users = usersRes.users || []

    const sorted = users
      .map(user => ({
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        createdAtSeconds: user.createdAt?._seconds ?? null,
      }))
      .filter(user => user.createdAtSeconds !== null)
      .sort((a, b) => b.createdAtSeconds - a.createdAtSeconds)
      .slice(0, 3)
      .map(user => ({
        ...user,
        createdAt: formatSecondsToDateString(user.createdAtSeconds),
      }))

    latestUsers.value = sorted
  } catch (err) {
    console.error('Error fetching admin dashboard data:', err)
    error.value = err?.message || 'Unknown error'
  } finally {
    loading.value = false
  }
}

onMounted(fetchDashboardData)
</script>
