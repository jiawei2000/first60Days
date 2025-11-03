<script setup>
import { computed, ref } from 'vue'

const userData = useCookie('userData')
const accessToken = useCookie('accessToken')

function decodeJwt(token) {
  try {
    const base64 = token.split('.')[1]
    return JSON.parse(atob(base64))
  } catch {
    return null
  }
}

const jwt = computed(() => accessToken.value ? decodeJwt(accessToken.value) : null)
// Prefer id from cookie (admin login sets it). Fallback to JWT.
const userId = computed(() => userData.value?.id || jwt.value?.id || null)
const role = computed(() => userData.value?.role || jwt.value?.role || 'guest')
const displayRole = computed(() => role.value.charAt(0).toUpperCase() + role.value.slice(1))

const form = ref({
  name: userData.value?.name || userData.value?.admin?.name || '',
  email: userData.value?.email || userData.value?.admin?.email || '',
  // Prefer cookie username so refresh shows latest change
  username: userData.value?.username || userData.value?.admin?.username || jwt.value?.username || '',
  newPassword: '',
})

const isTrainer = computed(() => role.value === 'trainer')
const saving = ref(false)
const snackbar = ref(false)
const snackbarMsg = ref('')

async function onSave() {
  saving.value = true
  try {
    // For trainers: update password if provided
    if (isTrainer.value && form.value.newPassword) {
      await $api('trainers/password', {
        method: 'PUT',
        body: { newPassword: form.value.newPassword },
        onResponseError({ response }) {
          throw new Error(response._data?.error || 'Failed to update password')
        },
      })
      form.value.newPassword = ''
    }

    // Update username if it changed
    const currentUsername = userData.value?.username || jwt.value?.username || ''
    if (form.value.username && userId.value && form.value.username !== currentUsername) {
      if (role.value === 'user') {
        await $api(`users/username/${userId.value}`, {
          method: 'PUT',
          body: { newUsername: form.value.username },
          onResponseError({ response }) {
            throw new Error(response._data?.error || 'Failed to update username')
          },
        })
      }

      // Persist latest username locally for all roles so UI reflects change
      userData.value = {
        ...(userData.value || {}),
        username: form.value.username,
      }

      // For admin/trainer, also store an override to survive re-login (frontend-only)
      if (role.value !== 'user') {
        try {
          const key = `usernameOverride:${role.value}:${userId.value}`
          localStorage.setItem(key, form.value.username)
          snackbarMsg.value = 'Username updated locally (frontend-only)'
        } catch (_) {
          // ignore storage errors
        }
      }
    }

    // Update name in userData cookie for all users (persists locally)
    const currentUserData = userData.value || {}
    userData.value = {
      ...currentUserData,
      name: form.value.name
    }

    snackbarMsg.value = 'Profile updated successfully'
  } catch (e) {
    snackbarMsg.value = e.message || String(e)
  } finally {
    saving.value = false
    snackbar.value = true
  }
}
</script>

<template>
  <div class="py-4 profile-page">
    <VRow>
      <VCol cols="12" md="4">
        <VCard class="h-100">
          <VCardText class="text-center pt-8">
            <VAvatar size="96" color="primary" variant="tonal">
              <VIcon icon="bx-user" size="40" />
            </VAvatar>
            <div class="text-h6 mt-4">
              {{ form.name || form.username || 'Unnamed' }}
            </div>
            <div class="text-medium-emphasis">
              {{ displayRole }}
            </div>
          </VCardText>
          <VDivider />

          <VList density="comfortable">
            <VListItem>
              <template #prepend><VIcon icon="bx-user" class="me-3" /></template>
              <VListItemTitle>{{ form.username || '—' }}</VListItemTitle>
              <VListItemSubtitle>Username</VListItemSubtitle>
            </VListItem>

            <VListItem>
              <template #prepend><VIcon icon="bx-envelope" class="me-3" /></template>
              <VListItemTitle>{{ form.email || '—' }}</VListItemTitle>
              <VListItemSubtitle>Email</VListItemSubtitle>
            </VListItem>
          </VList>
        </VCard>
      </VCol>

      <VCol cols="12" md="8">
        <VCard class="h-100">
          <VCardTitle class="px-6 pt-6">Profile</VCardTitle>
          <VCardText>
            <VForm @submit.prevent="onSave">
              <VRow>
                <VCol cols="12" md="6">
                  <VTextField :model-value="form.name" label="Name" readonly />
                </VCol>

                <VCol cols="12" md="6">
                  <VTextField v-model="form.email" label="Email" readonly />
                </VCol>

                <VCol cols="12" md="6">
                  <VTextField v-model="form.username" label="Username"/>
                </VCol>

                <VCol cols="12" md="6">
                  <VTextField :model-value="displayRole" label="Role" readonly />
                </VCol>

                <VCol v-if="isTrainer" cols="12" md="6">
                  <VTextField
                    v-model="form.newPassword"
                    type="password"
                    label="New Password (Trainer)"
                    placeholder="Change password"
                  />
                </VCol>

                <VCol cols="12" class="d-flex">
                  <VSpacer />
                  <VBtn color="primary" type="submit" :loading="saving">Save</VBtn>
                </VCol>
              </VRow>
            </VForm>
          </VCardText>
        </VCard>
      </VCol>
    </VRow>

    <VRow v-if="isTrainer" class="mt-4">
      <VCol cols="12">
        <VCard>
          <VCardTitle class="px-6 pt-6">Assigned Babies</VCardTitle>
          <VCardText>
            <div class="text-medium-emphasis">
              This section will list assigned babies. Integration pending.
            </div>
          </VCardText>
        </VCard>
      </VCol>
    </VRow>

    <VSnackbar v-model="snackbar" timeout="3000">
      {{ snackbarMsg }}
      <template #actions>
        <VBtn variant="text" color="primary" @click="snackbar = false">Close</VBtn>
      </template>
    </VSnackbar>
  </div>
</template>

<style scoped>
.profile-page { min-height: calc(100vh - 120px); }
</style>

