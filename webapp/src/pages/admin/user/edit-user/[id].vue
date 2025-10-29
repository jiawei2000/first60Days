<template>
    <VCard title="Edit User">
        <VForm>
            <VCardText>
                <VRow>
                    <VCol cols="12" md="6">
                        <AppTextField label="Client ID" v-model="form.id" disabled />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppTextField label="Username" v-model="form.username" disabled />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppTextField label="Name" v-model="form.name" disabled />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppTextField label="Email" v-model="form.email" type="email" disabled />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppTextField label="Phone" v-model="form.phoneNo" type="number" disabled />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppSelect label="Trainer" v-model="form.trainerId" :items="trainerList" item-title="name"
                            item-value="id" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppTextField label="Created At" v-model="form.createdAt" disabled />
                    </VCol>
                    <VCol cols="12" md="6">
                        <AppTextField label="Last Login At" v-model="form.lastLoginAt" disabled />
                    </VCol>
                </VRow>

                <VRow class="mt-4">
                    <VCol cols="auto">
                        <VBtn variant="outlined" color="primary" @click="editUser">Edit</VBtn>
                    </VCol>
                    <VCol cols=" auto">
                        <VBtn variant="outlined" color="secondary" @click="$router.push('/admin/user/manage-user')">
                            Cancel
                        </VBtn>
                    </VCol>
                </VRow>
            </VCardText>
        </VForm>
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
import { useRoute } from "vue-router"

definePage({
    meta: {
        adminOnly: true,
    },
})

const route = useRoute()

const currentUser = ref(null)

const isSnackBarVisible = ref(false)
const snackBarMessage = ref("")

const trainerList = ref([])

const form = ref({
    id: "",
    username: "",
    name: "",
    password: "",
    email: "",
    phoneNo: "",
    createdAt: "",
    lastLoginAt: "",
})

onMounted(async () => {
    await getUserById(route.params.id)
    await getTrainerList()

    // Populate form with fetched data
    form.value.id = currentUser.value.id
    form.value.username = currentUser.value.username
    form.value.name = currentUser.value.name
    form.value.email = currentUser.value.email
    form.value.phoneNo = currentUser.value.phoneNo
    form.value.createdAt = currentUser.value.createdAt
    form.value.lastLoginAt = currentUser.value.lastLoginAt
    form.value.trainerId = currentUser.value.trainerId
})

async function getUserById(userId) {
    try {
        const res = await $api('users/' + userId, {
            method: 'GET',
            onResponseError({ response }) {
                errors.value = response._data.errors
            }
        })
        currentUser.value = {
            id: res.id,
            name: res.name,
            username: res.username,
            email: res.email,
            phoneNo: res.phoneNo,
            createdAt: res.createdAt ? formatSecondsToDateString(res.createdAt._seconds) : "NA",
            lastLoginAt: res.lastLoginAt ? formatSecondsToDateString(res.lastLoginAt._seconds) : "NA",
            trainerId: res.trainerID?._path?.segments[1] || null
        }
    } catch (error) {
        console.error("Error fetching users:", error)
    }
}

async function getTrainerList() {
    try {
        const res = await $api('admins/trainers', {
            method: 'GET',
            onResponseError({ response }) {
                throw new Error(response._data.error)
            }
        })
        trainerList.value = res.trainers.map(trainer => ({
            id: trainer.id,
            name: trainer.name,
        }))

        form.value.trainerId = trainerList.value[0]?.id || "No trainers available"
    } catch (error) {
        snackBarMessage.value = error
        isSnackBarVisible.value = true
    }
}

function editUser() {
    //TO DO: Add API call and error handling
}



</script>
