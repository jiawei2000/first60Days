<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from '@/plugins/axios'
import AuthProvider from '@/views/pages/authentication/AuthProvider.vue'
import { themeConfig } from '@themeConfig'
import authV2LoginIllustration from '@images/pages/auth-v2-login-illustration.png'
import { useToken } from '@/composables/useToken'
import { VNodeRenderer } from '@layouts/components/VNodeRenderer'
import { definePage } from '@core/utils'

definePage({
  meta: {
    layout: 'blank',
    public: true,
  },
})

const router = useRouter()
const { setToken } = useToken()

// Local state
const form = ref({
  email: '',
  password: '',
  remember: false,
})

const isPasswordVisible = ref(false)
const isLoading = ref(false)
const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

// Login logic
const handleLogin = async () => {
  isLoading.value = true
  try {
      const response = await axios.post('/admin/login', {
      username: form.value.email,
      password: form.value.password,
    })

    const { token } = response.data
    setToken(token, form.value.remember)

    snackBarMessage.value = 'Login successful!'
    isSnackBarVisible.value = true

    router.push({ name: 'root' })
  } catch (err) {
    snackBarMessage.value = 'Login failed. Please check your credentials.'
    isSnackBarVisible.value = true
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <VApp>
    <a href="javascript:void(0)">
      <div class="auth-logo d-flex align-center gap-x-2">
        <VNodeRenderer :nodes="themeConfig.app.logo" />
        <h1 class="auth-title">{{ themeConfig.app.title }}</h1>
      </div>
    </a>

    <VRow no-gutters class="auth-wrapper bg-surface">
      <VCol md="8" class="d-none d-md-flex">
        <div class="position-relative bg-background w-100 pa-8">
          <div class="d-flex align-center justify-center w-100 h-100">
            <VImg
              max-width="700"
              :src="authV2LoginIllustration"
              class="auth-illustration"
            />
          </div>
        </div>
      </VCol>

      <VCol cols="12" md="4" class="auth-card-v2 d-flex align-center justify-center">
        <VCard flat :max-width="500" class="mt-12 mt-sm-0 pa-6">
          <VCardText>
            <h4 class="text-h4 mb-1">
              Welcome to <span class="text-capitalize">{{ themeConfig.app.title }}</span>! 👋🏻
            </h4>
            <p class="mb-0">Please sign-in to your account and start the adventure</p>
          </VCardText>

          <VCardText>
            <VForm @submit.prevent="handleLogin">
              <VRow>
                <VCol cols="12">
                  <AppTextField
                    v-model="form.email"
                    autofocus
                    label="Email or Username"
                    type="email"
                    placeholder="johndoe@email.com"
                  />
                </VCol>

                <VCol cols="12">
                  <AppTextField
                    v-model="form.password"
                    label="Password"
                    placeholder="············"
                    :type="isPasswordVisible ? 'text' : 'password'"
                    autocomplete="password"
                    :append-inner-icon="isPasswordVisible ? 'bx-hide' : 'bx-show'"
                    @click:append-inner="isPasswordVisible = !isPasswordVisible"
                  />

                  <div class="d-flex align-center flex-wrap justify-space-between my-6">
                    <VCheckbox v-model="form.remember" label="Remember me" />
                    <a class="text-primary" href="javascript:void(0)">Forgot Password?</a>
                  </div>

                  <VBtn block type="submit" :loading="isLoading">Login</VBtn>
                </VCol>

                <VCol cols="12" class="text-body-1 text-center">
                  <span class="d-inline-block"> New on our platform? </span>
                  <a class="text-primary ms-1 d-inline-block text-body-1" href="javascript:void(0)">
                    Create an account
                  </a>
                </VCol>

                <VCol cols="12" class="d-flex align-center">
                  <VDivider />
                  <span class="mx-4">or</span>
                  <VDivider />
                </VCol>

                <VCol cols="12" class="text-center">
                  <AuthProvider />
                </VCol>
              </VRow>
            </VForm>
          </VCardText>
        </VCard>
      </VCol>
    </VRow>

    <!-- Snackbar -->
    <VSnackbar
      v-model="isSnackBarVisible"
      timeout="4000"
      location="top right"
    >
      {{ snackBarMessage }}

      <template #actions>
        <VBtn color="error" variant="text" @click="isSnackBarVisible = false">Close</VBtn>
      </template>
    </VSnackbar>
  </VApp>
</template>

<style lang="scss">
@use "@core/scss/template/pages/page-auth";
</style>
