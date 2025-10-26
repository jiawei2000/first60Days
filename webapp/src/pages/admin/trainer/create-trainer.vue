<template>
    <VCard title="Create Trainer">
        <VForm>
            <VCardText>
                <VRow>
                    <VCol cols="12" md="6">
                        <VTextField label="Username" v-model="form.username" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Name" v-model="form.name" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Email" v-model="form.email" type="email" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Password" v-model="form.password" type="password" />
                    </VCol>
                </VRow>

                <VRow class="mt-4">
                    <VCol cols="auto">
                        <VBtn color="primary" @click="createTrainer">Create</VBtn>
                    </VCol>
                    <VCol cols="auto">
                        <VBtn color="secondary" @click="$router.push('/admin/trainer/manage-trainer')">Cancel</VBtn>
                    </VCol>
                </VRow>
            </VCardText>
        </VForm>
    </VCard>

    <VSnackbar v-model="isSnackBarVisible" timeout="5000">
        {{ snackBarMessage }}
        <template #actions>
            <VBtn color="error" @click="isSnackBarVisible = false">Close</VBtn>
        </template>
    </VSnackbar>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

definePage({
    meta: {
        adminOnly: true,
    },
})

const router = useRouter()

const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

const form = ref({
    username: '',
    name: '',
    email: '',
    password: '',
})

async function createTrainer() {
    try {
        await $api('admins/registerTrainer', {
            method: 'POST',
            body: {
                username: form.value.username,
                name: form.value.name,
                email: form.value.email,
                password: form.value.password,
            },
            onResponseError({ response }) {
                throw new Error(response._data.error)
            },
        })

        // Reset form and notify
        form.value = {
            username: '',
            name: '',
            email: '',
            password: '',
        }

        snackBarMessage.value = 'Trainer created successfully!'
        isSnackBarVisible.value = true

        // Optionally navigate after a short delay
        setTimeout(() => {
            router.push('/admin/trainer/manage-trainer')
        }, 1000)
    } catch (error) {
        snackBarMessage.value = error.message || 'Something went wrong.'
        isSnackBarVisible.value = true
    }
}
</script>
