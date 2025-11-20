<template>
    <VContainer>

        <!-- Page Title -->
        <VCard title="Trainer Dashboard">
            <VCardText>

                <!-- LOADING -->
                <div v-if="loading" class="text-medium-emphasis">
                    Loading dashboard data...
                </div>

                <!-- ERROR -->
                <div v-else-if="error" class="text-error">
                    Failed to load trainer dashboard: {{ error }}
                </div>

                <!-- CONTENT -->
                <div v-else>

                    <!-- METRICS ROW -->
                    <VRow class="mb-6">
                        <VCol cols="12" md="4">
                            <VCard class="pa-4 d-flex align-center" elevation="1">
                                <VAvatar size="48" class="me-4" color="primary" variant="tonal">
                                    <VIcon icon="bx-group" />
                                </VAvatar>
                                <div>
                                    <p class="text-caption text-medium-emphasis mb-0">
                                        Parents Assigned
                                    </p>
                                    <h3 class="text-h5 font-weight-bold mb-0">
                                        {{ metrics.parentsAssigned }}
                                    </h3>
                                </div>
                            </VCard>
                        </VCol>

                        <VCol cols="12" md="4">
                            <VCard class="pa-4 d-flex align-center" elevation="1">
                                <VAvatar size="48" class="me-4" color="info" variant="tonal">
                                    <VIcon icon="bx-baby" />
                                </VAvatar>
                                <div>
                                    <p class="text-caption text-medium-emphasis mb-0">
                                        Babies Assigned
                                    </p>
                                    <h3 class="text-h5 font-weight-bold mb-0">
                                        {{ metrics.babiesAssigned }}
                                    </h3>
                                </div>
                            </VCard>
                        </VCol>

                        <VCol cols="12" md="4">
                            <VCard class="pa-4 d-flex align-center" elevation="1">
                                <VAvatar size="48" class="me-4" color="error" variant="tonal">
                                    <VIcon icon="bx-error" />
                                </VAvatar>
                                <div>
                                    <p class="text-caption text-medium-emphasis mb-0">
                                        Babies with Alerts
                                    </p>
                                    <h3 class="text-h5 font-weight-bold mb-0">
                                        {{ metrics.babiesWithAlerts }}
                                    </h3>
                                </div>
                            </VCard>
                        </VCol>
                    </VRow>

                    <!-- ASSIGNED BABIES TABLE -->
                    <VCard>
                        <VCardTitle class="text-subtitle-1 font-weight-bold">
                            Assigned Babies
                        </VCardTitle>

                        <VCardText>
                            <VDataTable :headers="headers" :items="assignedBabies" :items-per-page="10">
                                <!-- ACTIONS -->
                                <template #item.actions="{ item }">
                                    <div class="d-flex gap-1">
                                        <IconBtn :to="`/trainer/user/view-baby/${item.id}`">
                                            <VIcon icon="bx-calendar" />
                                        </IconBtn>

                                        <IconBtn :to="`/trainer/user/view-stats/${item.id}`">
                                            <VIcon icon="bx-bar-chart" />
                                        </IconBtn>
                                    </div>
                                </template>

                                <!-- ALERT ICON -->
                                <template #item.hasAlert="{ item }">
                                    <VChip :color="resolveStatusVariant(item.hasAlert).color" size="small">
                                        {{ resolveStatusVariant(item.hasAlert).text }}
                                    </VChip>
                                </template>
                                <!-- <template #item.hasAlert="{ item }">
                  <VChip v-if="item.hasAlert" color="error" size="small" label>
                    Alert
                  </VChip>
                  <span v-else class="text-medium-emphasis text-caption">
                    Normal
                  </span>
                </template> -->
                            </VDataTable>
                        </VCardText>
                    </VCard>

                </div>
            </VCardText>
        </VCard>

        <!-- Snackbar -->
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

definePage({ meta: { trainerOnly: true } })

const loading = ref(true)
const error = ref(null)

const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

const metrics = ref({
    parentsAssigned: 0,
    babiesAssigned: 0,
    babiesWithAlerts: 0
})

const assignedBabies = ref([])

const resolveStatusVariant = (status) => {
    if (status === "true")
        return { color: 'error', text: "Alert" }
    else
        return { color: 'success', text: "Normal" }
}
const headers = [
    { title: "Baby", key: "name" },
    { title: "Parent", key: "parentName" },
    { title: "Gender", key: "gender" },
    { title: "Alert", key: "hasAlert" },
    { title: "Actions", key: "actions", sortable: false },
]

function isStaleDate(dateString) {
    if (!dateString) return true
    const statDate = new Date(dateString)
    const now = new Date()
    const diffMs = now - statDate
    const diffDays = diffMs / (1000 * 60 * 60 * 24)
    return diffDays > 1
}

async function fetchTrainerDashboard() {
    loading.value = true
    error.value = null

    try {
        const usersRes = await $api('trainers/users', { method: 'GET' })
        const users = usersRes.users || []

        const babyResponses = await Promise.all(
            users.map(user => $api(`trainers/users/${user.id}/babies`, { method: 'GET' }))
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

        const statsResponses = await Promise.all(
            babiesList.map(async baby => {
                try {
                    const res = await $api(`statistics/daily/baby/${baby.id}`, { method: 'GET' })
                    return { babyId: baby.id, statistics: res.data?.statistics || [] }
                } catch {
                    return { babyId: baby.id, statistics: [] }
                }
            })
        )

        const alertsSet = new Set()
        statsResponses.forEach(({ babyId, statistics }) => {
            if (!statistics.length) alertsSet.add(babyId)
            else if (isStaleDate(statistics.at(-1)?.date)) alertsSet.add(babyId)
        })

        assignedBabies.value = babiesList.map(baby => ({
            ...baby,
            hasAlert: alertsSet.has(baby.id)
        }))

        metrics.value.parentsAssigned = users.length
        metrics.value.babiesAssigned = babiesList.length
        metrics.value.babiesWithAlerts = alertsSet.size

    } catch (err) {
        console.error(err)
        error.value = err?.message || 'Unknown error'
    } finally {
        loading.value = false
    }
}

onMounted(fetchTrainerDashboard)
</script>
