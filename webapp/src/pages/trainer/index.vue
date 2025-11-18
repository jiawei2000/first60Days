<template>
  <VContainer>
    <VRow class="mb-4">
      <VCol cols="12">
        <h1 class="text-h4 font-weight-bold">Trainer Dashboard</h1>
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
          Failed to load trainer dashboard: {{ error }}
        </div>
      </VCol>
    </VRow>

    <VRow v-else>
      <VCol cols="12" md="4">
        <VCard>
          <VCardText class="d-flex flex-column">
            <span class="text-subtitle-2 text-medium-emphasis mb-1">Parents Assigned</span>
            <span class="text-h4 font-weight-bold">{{ metrics.parentsAssigned }}</span>
          </VCardText>
        </VCard>
      </VCol>

      <VCol cols="12" md="4">
        <VCard>
          <VCardText class="d-flex flex-column">
            <span class="text-subtitle-2 text-medium-emphasis mb-1">Babies Assigned</span>
            <span class="text-h4 font-weight-bold">{{ metrics.babiesAssigned }}</span>
          </VCardText>
        </VCard>
      </VCol>

      <VCol cols="12" md="4">
        <VCard>
          <VCardText class="d-flex flex-column">
            <span class="text-subtitle-2 text-medium-emphasis mb-1">Babies with Alerts</span>
            <span class="text-h4 font-weight-bold">{{ metrics.babiesWithAlerts }}</span>
          </VCardText>
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
            Assigned Babies
          </VCardTitle>
          <VCardText>
            <VTable density="compact">
              <thead>
                <tr>
                  <th class="text-left">
                    Baby
                  </th>
                  <th class="text-left">
                    Parent
                  </th>
                  <th class="text-left">
                    Gender
                  </th>
                  <th class="text-left">
                    Alert
                  </th>
                  <th class="text-left">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="!assignedBabies.length">
                  <td
                    colspan="5"
                    class="text-medium-emphasis text-center"
                  >
                    No assigned babies found.
                  </td>
                </tr>
                <tr
                  v-for="baby in assignedBabies"
                  :key="baby.id"
                >
                  <td>{{ baby.name || 'Unnamed' }}</td>
                  <td>{{ baby.parentName || 'Unknown' }}</td>
                  <td>{{ baby.gender || 'N/A' }}</td>
                  <td>
                    <VChip
                      v-if="baby.hasAlert"
                      color="error"
                      size="small"
                      label
                    >
                      Alert
                    </VChip>
                    <span
                      v-else
                      class="text-medium-emphasis text-caption"
                    >
                      OK
                    </span>
                  </td>
                  <td>
                    <div class="d-flex gap-1">
                      <IconBtn :to="`/trainer/user/view-baby/${baby.id}`">
                        <VIcon icon="bx-calendar" />
                      </IconBtn>
                      <IconBtn :to="`/trainer/user/view-stats/${baby.id}`">
                        <VIcon icon="bx-bar-chart" />
                      </IconBtn>
                    </div>
                  </td>
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

definePage({
  meta: {
    trainerOnly: true,
  },
})

const loading = ref(true)
const error = ref(null)

const metrics = ref({
  parentsAssigned: 0,
  babiesAssigned: 0,
  babiesWithAlerts: 0,
})

const assignedBabies = ref([])

function isStaleDate(dateString) {
  if (!dateString)
    return true

  const statDate = new Date(dateString)
  if (Number.isNaN(statDate.getTime()))
    return true

  const now = new Date()
  const diffMs = now.getTime() - statDate.getTime()
  const diffDays = diffMs / (1000 * 60 * 60 * 24)

  // Simple rule of thumb: alert if last stats are older than 1 day
  return diffDays > 1
}

async function fetchTrainerDashboard() {
  loading.value = true
  error.value = null

  try {
    // 1. Get parents assigned to this trainer
    const usersRes = await $api('trainers/users', {
      method: 'GET',
      onResponseError({ response }) {
        throw new Error(response._data)
      },
    })

    const users = usersRes.users || []

    // 2. For each parent, get their babies
    const babyResponses = await Promise.all(
      users.map(user =>
        $api(`trainers/users/${user.id}/babies`, {
          method: 'GET',
          onResponseError({ response }) {
            throw new Error(response._data)
          },
        }),
      ),
    )

    const babiesMap = new Map()

    babyResponses.forEach((res, index) => {
      const parent = users[index]
      const babies = res.babies || []

      babies.forEach(baby => {
        if (!babiesMap.has(baby.id)) {
          babiesMap.set(baby.id, {
            id: baby.id,
            name: baby.name,
            gender: baby.gender,
            parentName: parent.name,
            hasAlert: false,
          })
        }
      })
    })

    const babiesList = Array.from(babiesMap.values())

    // 3. For each baby, fetch latest daily stats and mark simple alerts
    const statsResponses = await Promise.all(
      babiesList.map(async baby => {
        try {
          const res = await $api(`statistics/daily/baby/${baby.id}`, {
            method: 'GET',
          })

          const statistics = res.data?.statistics || []
          return { babyId: baby.id, statistics }
        } catch {
          return { babyId: baby.id, statistics: [] }
        }
      }),
    )

    const alertsSet = new Set()

    statsResponses.forEach(({ babyId, statistics }) => {
      if (!statistics.length) {
        alertsSet.add(babyId)
        return
      }

      // Backend already sorts ascending, but ensure just in case
      const latest = statistics[statistics.length - 1]
      if (isStaleDate(latest.date))
        alertsSet.add(babyId)
    })

    const enrichedBabies = babiesList.map(baby => ({
      ...baby,
      hasAlert: alertsSet.has(baby.id),
    }))

    assignedBabies.value = enrichedBabies

    metrics.value.parentsAssigned = users.length
    metrics.value.babiesAssigned = babiesList.length
    metrics.value.babiesWithAlerts = alertsSet.size
  } catch (err) {
    console.error('Error fetching trainer dashboard data:', err)
    error.value = err?.message || 'Unknown error'
  } finally {
    loading.value = false
  }
}

onMounted(fetchTrainerDashboard)
</script>
