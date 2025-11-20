<script setup>
import { ref } from 'vue'
import { useRouter } from "vue-router"
import first60daysLogo from '@/assets/images/cards/first60days_logo.png'


const router = useRouter()

definePage({
    meta: {
        layout: 'blank',
        unauthenticatedOnly: true,
    },
})

const form = ref({
    username: '',
    password: '',
    remember: false,
})

const isPasswordVisible = ref(false)
const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

async function loginTrainer() {
    try {
        const res = await $api('trainers/login', {
            method: 'POST',
            body: {
                username: form.value.username,
                password: form.value.password,
            },
            onResponseError({ response }) {
                throw new Error(response._data.error)
            }
        })
        isSnackBarVisible.value = true
        snackBarMessage.value = "Login successful!"

        useCookie('accessToken').value = res.token
        useCookie('userData').value = {
            name: res.trainer.name,
            role: 'trainer',
            email: res.trainer.email,
            username: res.trainer.username,
            id: res.trainer.id,
        }
        // Frontend-only username override persistence for Trainer
        try {
          const id = res.trainer?.id
          if (id) {
            const key = `usernameOverride:trainer:${id}`
            const override = localStorage.getItem(key)
            if (override) {
              const cookie = useCookie('userData')
              cookie.value = { ...(cookie.value || {}), username: override }
            }
          }
        } catch (_) {}
        router.push({ name: 'trainer' })

    } catch (error) {
        snackBarMessage.value = error
        isSnackBarVisible.value = true
    }
}

</script>

<template>
    <div class="d-flex align-center justify-center pa-4">
        <VCard class="auth-card" max-width="460" :class="$vuetify.display.smAndUp ? 'pa-6' : 'pa-0'">
            <VCardItem class="justify-cente">
                <img :src="first60daysLogo" alt="Logo"
                    style="width: 200px; height: auto; display:block; margin: 20px auto;" />
            </VCardItem>

            <VCardText>
                <h4 class="text-h4 mb-1 text-center">
                    Trainer Portal
                </h4>
            </VCardText>

            <VCardText>
                <VForm @submit.prevent="loginTrainer">
                    <VRow>
                        <!-- username -->
                        <VCol cols="12">
                            <AppTextField v-model="form.username" autofocus label="Username" type="text" />
                        </VCol>

                        <!-- password -->
                        <VCol cols="12">
                            <AppTextField v-model="form.password" label="Password" placeholder="············"
                                :type="isPasswordVisible ? 'text' : 'password'" autocomplete="password"
                                :append-inner-icon="isPasswordVisible ? 'bx-hide' : 'bx-show'"
                                @click:append-inner="isPasswordVisible = !isPasswordVisible" />

                            <!-- remember me checkbox -->
                            <div class="d-flex align-center justify-space-between flex-wrap my-6">
                                <VCheckbox v-model="form.remember" label="Remember me" />

                                <!-- Forget Password -->
                                <!-- <RouterLink class="text-primary">
                                        Forgot Password?
                                    </RouterLink> -->
                            </div>

                            <!-- login button -->
                            <VBtn block type="submit" color="primary">
                                Login
                            </VBtn>
                        </VCol>

                        <!-- create account -->
                        <VCol cols="12" class="text-body-1 text-center">
                            <span class="d-inline-block"> Are you an Admin? </span>
                            <RouterLink class="text-primary ms-1 d-inline-block text-body-1"
                                :to="{ name: 'admin-login' }">
                                Admin Login
                            </RouterLink>
                        </VCol>
                    </VRow>
                </VForm>
            </VCardText>
        </VCard>
    </div>
    <VSnackbar v-model="isSnackBarVisible" timeout="5000">
        {{ snackBarMessage }}
        <template #actions>
            <VBtn color="error" @click="isSnackBarVisible = false">
                Close
            </VBtn>
        </template>
    </VSnackbar>
</template>

<style lang="scss">
@use "@core/scss/template/pages/page-auth";
</style>

