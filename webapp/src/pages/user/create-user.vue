<template>
    <VCard title="Create User">

        <!-- Form -->
        <VForm>
            <VCardText>
                <VRow>
                    <VCol cols="12" md="6">
                        <VTextField label="Username" v-model="form.username" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Password" v-model="form.password" type="password" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Email" v-model="form.email" type="email" />
                    </VCol>
                    <VCol cols="12" md="6">
                        <VTextField label="Phone" v-model="form.phone" type="number" />
                    </VCol>
                </VRow>

                <!-- Action Buttons -->
                <VRow class="mt-4">
                    <VCol cols="auto">
                        <VBtn color="primary">Create</VBtn>
                    </VCol>
                    <VCol cols=" auto">
                        <VBtn color="secondary" @click="$router.push('/user/manage-user')">Cancel</VBtn>
                    </VCol>
                </VRow>
            </VCardText>
        </VForm>
    </VCard>
</template>

<script setup>
import { ref } from "vue"
import { useRouter } from "vue-router"

const router = useRouter()

// User form state
const form = ref({
    username: "",
    email: "",
    password: "",
    phoneNo: "",
})

// create user
function createUser() {
    console.log("User Data Submitted:", form.value)
}


</script>