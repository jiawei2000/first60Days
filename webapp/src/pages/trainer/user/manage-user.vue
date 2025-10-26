<template>
    <VCard title="Manage Users">
        <VCardText>
            <VRow>
                <VCol>
                    <VTextField v-model="search" placeholder="Try ... Users created in 2024"
                        append-inner-icon="bx-search" />
                </VCol>
                <VCol>
                    <VBtn color="secondary" class="mr-2" @click="">Search</VBtn>
                </VCol>
            </VRow>

            <VSpacer class="my-6" />

            <VDataTable :headers="headers" :items="data" :items-per-page="10">
                <!-- Actions -->
                <template #item.actions="{ item }">
                    <div class="d-flex gap-1">
                        <IconBtn @click="editUser(item)">
                            <VIcon icon="bx-edit" />
                        </IconBtn>
                    </div>
                </template>
            </VDataTable>
        </VCardText>
    </VCard>
    <VSnackbar v-model="isSnackBarVisible" timeout="5000">
        {{ snackBarMessage }}
        <template #actions>
            <VBtn color="error" @click="isSnackBarVisible = false">
                Close
            </VBtn>
        </template>
    </VSnackbar>
</template>
<script setup>
import { onMounted, ref } from "vue"
import { useRouter } from "vue-router"

definePage({
    meta: {
        trainerOnly: true,
    },
})

const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

const router = useRouter()

const search = ref("")
const data = ref([])

const headers = [
    { title: "Username", key: "username" },
    { title: "Name", key: "name" },
    { title: "Email", key: "email" },
    { title: "Phone No", key: "phoneNo" },
    { title: "Created At", key: "createdAt" },
    { title: "Last Login", key: "lastLoginAt" },
    { title: "Actions", value: "actions", sortable: false },
]

onMounted(() => {
    getUsers()
})

async function getUsers() {
    try {
        const res = await $api('trainers/users', {
            method: 'GET',
            onResponseError({ response }) {
                throw new Error(response._data)
            }
        })

        data.value = res.users.map(user => ({
            id: user.id,
            username: user.username,
            name: user.name,
            email: user.email,
            phoneNo: user.phoneNo,
            relation: user.relation,
            lastLoginAt: user.lastLoginAt ? formatSecondsToDateString(user.lastLoginAt._seconds) : "NA",
            createdAt: user.createdAt ? formatSecondsToDateString(user.createdAt._seconds) : "NA",
        }))

    } catch (error) {
        snackBarMessage.value = error
        isSnackBarVisible.value = true
    }
}

function editUser(item) {
    snackBarMessage.value = `Editing user: ${item.name}`
    isSnackBarVisible.value = true
}
</script>