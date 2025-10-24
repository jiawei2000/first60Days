<template>
    <VCard title="Create User">
        <VForm>
            <VCardText>
                <VRow>
                    <VCol cols="12" md="6">
                        <VTextField label="Username" v-model="form.username" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Name" v-model="form.name" />
                    </VCol>
                    <VCol cols="12" md="12">
                        <VTextField label="Email" v-model="form.email" type="email" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Password" v-model="form.password" type="password" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Phone" v-model="form.phoneNo" type="number" />
                    </VCol>
                </VRow>
                <VRow class="mt-4">
                    <VCol cols="auto">
                        <VBtn color="primary" @click="createUser">Create</VBtn>
                    </VCol>
                    <VCol cols=" auto">
                        <VBtn color="secondary" @click="$router.push('/user/manage-user')">Cancel</VBtn>
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
import { ref } from "vue"

const isSnackBarVisible = ref(false)
const snackBarMessage = ref("")

// User form state
const form = ref({
    username: "",
    name: "",
    email: "",
    password: "",
    phoneNo: "",
})

// create user
async function createUser() {
    try {
        const res = await $api('users', {
            method: 'POST',
            body: {
                username: form.value.username,
                name: form.value.name,
                email: form.value.email,
                password: form.value.password,
                phoneNo: form.value.phoneNo,
            },
            onResponseError({ response }) {
                throw new Error(response._data.error)
            }
        })

        // After successful creation, reset form and show snackbar
        form.value = {
            username: "",
            name: "",
            email: "",
            password: "",
            phoneNo: "",
        }
        isSnackBarVisible.value = true
        snackBarMessage.value = "User created successfully!"
    } catch (error) {
        snackBarMessage.value = error
        isSnackBarVisible.value = true
    }
}

</script>