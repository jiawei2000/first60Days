<template>
    <VCard title="Manage Users">
        <VCardText>
            <VRow>
                <VCol>
                    <VTextField v-model="search" placeholder="Try ... Users created in 2024"
                        append-inner-icon="bx-search" />
                </VCol>
                <VCol class="d-flex justify-end">
                    <VBtn color="secondary" class="mr-2" @click="">Search</VBtn>
                    <VBtn color="primary" @click="$router.push('/user/create-user')">Create New User</VBtn>
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
</template>

<script setup>
import { onMounted, ref } from "vue"
import { useRouter } from "vue-router"

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
        const res = await $api('users', {
            method: 'GET',
            onResponseError({ response }) {
                errors.value = response._data.errors
            }
        })

        data.value = res.map(user => ({
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
        console.error("Error fetching users:", error)
    }
}

function editUser(user) {
    router.push(`/user/edit-user/${user.id}`)
}

</script>
