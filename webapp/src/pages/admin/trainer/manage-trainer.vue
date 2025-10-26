<template>
    <VCard title="Manage Trainers">
        <VCardText>
            <VRow>
                <VCol>
                    <VTextField v-model="search" placeholder="Try ... Trainers created in 2024"
                        append-inner-icon="bx-search" />
                </VCol>
                <VCol class="d-flex justify-end">
                    <VBtn color="secondary" class="mr-2" @click="">Search</VBtn>
                    <VBtn color="primary" @click="$router.push('/admin/trainer/create-trainer')">
                        Create New Trainer
                    </VBtn>
                </VCol>
            </VRow>

            <VSpacer class="my-6" />

            <VDataTable :headers="headers" :items="data" :items-per-page="10">
                <!-- Actions -->
                <template #item.actions="{ item }">
                    <div class="d-flex gap-1">
                        <IconBtn @click="editTrainer(item)">
                            <VIcon icon="bx-edit" />
                        </IconBtn>
                    </div>
                </template>
            </VDataTable>
        </VCardText>
    </VCard>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

definePage({
    meta: {
        adminOnly: true,
    },
})

// Format Firestore timestamp to readable string
function formatSecondsToDateString(seconds) {
    const date = new Date(seconds * 1000)
    return date.toLocaleString()
}

const router = useRouter()
const search = ref('')
const data = ref([])

const headers = [
    { title: 'Username', key: 'username' },
    { title: 'Name', key: 'name' },
    { title: 'Email', key: 'email' },
    { title: 'Created At', key: 'createdAt' },
    { title: 'Last Login', key: 'lastLoginAt' },
    { title: 'Actions', value: 'actions', sortable: false },
]

onMounted(() => {
    getTrainers()
})

async function getTrainers() {
    try {
        const res = await $api('admins/trainers', {
            method: 'GET',
            onResponseError({ response }) {
                console.error(response._data?.error || 'API error')
            },
        })

        data.value = res.trainers.map(trainer => ({
            id: trainer.id,
            username: trainer.username,
            name: trainer.name,
            email: trainer.email,
            lastLoginAt: trainer.lastLoginAt
                ? formatSecondsToDateString(trainer.lastLoginAt._seconds)
                : 'NA',
            createdAt: trainer.createdAt
                ? formatSecondsToDateString(trainer.createdAt._seconds)
                : 'NA',
        }))
    } catch (err) {
        console.error('Failed to fetch trainers:', err)
    }
}

function editTrainer(trainer) {
    router.push(`/admin/trainer/edit-trainer/${trainer.id}`)
}
</script>
