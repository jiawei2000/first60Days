<template>
  <VCard title="Manage Users">
    <VCardText>
      <VRow>
        <VCol>
          <VTextField
            v-model="search"
            placeholder="Try: 'Show users created in 2025'"
            append-inner-icon="bx-search"
            @keyup.enter="performSearch"
          />
        </VCol>
        <VCol class="d-flex justify-end">
          <VBtn color="secondary" class="mr-2" @click="clearSearch">Clear</VBtn>
          <VBtn color="primary" class="mr-2" @click="performSearch">Search</VBtn>
          <VBtn
            color="success"
            @click="$router.push('/admin/user/create-user')"
          >
            Create New User
          </VBtn>
        </VCol>
      </VRow>

      <VSpacer class="my-6" />

      <!-- Loader when searching -->
      <div v-if="loading" class="text-center py-8">
        <VProgressCircular indeterminate color="primary" size="40" />
        <p class="mt-2 text-medium-emphasis">Loading users...</p>
      </div>

      <!-- Data Table -->
      <VDataTable
        v-else
        :headers="headers"
        :items="data"
        :items-per-page="10"
        class="elevation-1"
      >
        <!-- Actions -->
        <template #item.actions="{ item }">
          <div class="d-flex gap-1">
            <IconBtn @click="editUser(item)">
              <VIcon icon="bx-edit" />
            </IconBtn>
          </div>
        </template>
      </VDataTable>

      <!-- Empty state -->
      <div
        v-if="!loading && !data.length"
        class="text-center text-medium-emphasis py-4"
      >
        No users found. Try a different query.
      </div>
    </VCardText>

    <!-- Snackbar for errors -->
    <VSnackbar v-model="isSnackBarVisible" timeout="4000">
      {{ snackBarMessage }}
      <template #actions>
        <VBtn color="error" @click="isSnackBarVisible = false">Close</VBtn>
      </template>
    </VSnackbar>
  </VCard>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

definePage({
  meta: { adminOnly: true },
})

const router = useRouter()
const search = ref('')
const data = ref([])
const loading = ref(false)

const isSnackBarVisible = ref(false)
const snackBarMessage = ref('')

const headers = [
  { title: 'Username', key: 'username' },
  { title: 'Name', key: 'name' },
  { title: 'Email', key: 'email' },
  { title: 'Phone No', key: 'phoneNo' },
  { title: 'Created At', key: 'createdAt' },
  { title: 'Last Login', key: 'lastLoginAt' },
  { title: 'Actions', key: 'actions', sortable: false },
]

// Load all users initially
onMounted(() => {
  getUsers()
})

// Fetch default user list
async function getUsers() {
  try {
    loading.value = true
    const res = await $api('admins/users', {
      method: 'GET',
      onResponseError({ response }) {
        throw new Error(response._data?.error || 'Failed to load users')
      },
    })

    data.value = res.users.map((user) => ({
      id: user.id,
      username: user.username,
      name: user.name,
      email: user.email,
      phoneNo: user.phoneNo || 'N/A',
      relation: user.relation,
      lastLoginAt: user.lastLoginAt
        ? formatSecondsToDateString(user.lastLoginAt._seconds)
        : 'N/A',
      createdAt: user.createdAt
        ? formatSecondsToDateString(user.createdAt._seconds)
        : 'N/A',
    }))
  } catch (error) {
    snackBarMessage.value = error.message
    isSnackBarVisible.value = true
  } finally {
    loading.value = false
  }
}

// Perform AI search
async function performSearch() {
  if (!search.value.trim()) {
    await getUsers()
    return
  }

  try {
    loading.value = true
    data.value = []

    const res = await $api('assistant/users/query', {
      method: 'POST',
      body: { question: search.value },
      onResponseError({ response }) {
        throw new Error(response._data?.error || 'AI query failed')
      },
    })

    if (res?.results?.length) {
      data.value = res.results.map((user) => ({
        id: user.id,
        username: user.username || '-',
        name: user.name || '-',
        email: user.email || '-',
        phoneNo: user.phoneNo || '-',
        createdAt: user.createdAt
          ? formatSecondsToDateString(user.createdAt._seconds)
          : '-',
        lastLoginAt: user.lastLoginAt
          ? formatSecondsToDateString(user.lastLoginAt._seconds)
          : '-',
      }))
    } else {
      data.value = []
    }
  } catch (error) {
    console.error('❌ AI Search Error:', error)
    snackBarMessage.value = error.message
    isSnackBarVisible.value = true
  } finally {
    loading.value = false
  }
}

// Clear search
function clearSearch() {
  search.value = ''
  getUsers()
}
// Navigate to edit user
function editUser(user) {
  router.push(`/admin/user/edit-user/${user.id}`)
}
</script>

<style scoped>
.text-truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
