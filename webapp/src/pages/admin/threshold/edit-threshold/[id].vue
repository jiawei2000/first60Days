<template>
  <VContainer class="pa-6">
    <VCard elevation="2" class="pa-4">
      <VCardTitle class="text-h5 font-weight-bold mb-2">
        Edit Threshold
      </VCardTitle>

      <VCardSubtitle class="text-medium-emphasis mb-6">
        Adjust weekly or daily threshold values for each metric.
      </VCardSubtitle>

      <VCardText>
        <VRow class="mb-4">
          <!-- Table Name (readonly) -->
          <VCol cols="12" md="4">
            <VTextField
              v-model="formattedTableName"
              label="Table Name"
              variant="outlined"
              readonly
              density="comfortable"
              class="rounded-lg"
            />
          </VCol>

          <!-- Key (readonly) -->
          <VCol cols="12" md="4">
            <VTextField
              v-model="formattedKey"
              label="Metric Key"
              variant="outlined"
              readonly
              density="comfortable"
              class="rounded-lg"
            />
          </VCol>
        </VRow>

        <!-- Description (visible info block) -->
        <div class="mb-6">
          <p class="text-caption text-medium-emphasis mb-1">Description</p>
          <VCard class="pa-4 bg-grey-lighten-4 text-body-2 rounded-lg" elevation="0">
            {{ description || 'No description available.' }}
          </VCard>
        </div>

        <!-- Editable week/value table -->
        <h3 class="text-h6 font-weight-medium mb-3">
          {{ formattedTableName }} Values
        </h3>

        <VDataTable
          :headers="headers"
          :items="weekValues"
          hide-default-footer
          class="elevation-1 mb-6"
        >
          <template #item.value="{ item }">
            <VTextField
              v-model="item.value"
              density="comfortable"
              variant="outlined"
              :error="item.error"
              :error-messages="item.errorMsg"
              hide-details="auto"
              class="rounded-lg"
              @input="validateValue(item)"
            />
          </template>
        </VDataTable>
      </VCardText>

      <!-- Actions -->
      <VCardActions class="d-flex justify-end">
        <VBtn color="primary" class="px-6" @click="saveChanges" :loading="saving">
          Confirm
        </VBtn>
        <VBtn color="secondary" variant="tonal" class="px-6" @click="$router.back()">
          Cancel
        </VBtn>
      </VCardActions>
    </VCard>

    <!-- ✅ Success Snackbar -->
    <VSnackbar
      v-model="snackbar"
      color="success"
      timeout="3000"
      rounded="pill"
      elevation="3"
      location="bottom center"
    >
      Threshold updated successfully!
    </VSnackbar>
  </VContainer>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

definePage({ meta: { adminOnly: true } })

const route = useRoute()
const router = useRouter()

const id = route.params.id
const tableName = ref(route.query.type || '')
const thresholdKey = ref('')
const description = ref('')
const saving = ref(false)
const snackbar = ref(false)

const weekValues = ref([])
const headers = [
  { title: 'Week', key: 'week', align: 'center' },
  { title: 'Value', key: 'value', align: 'center' },
]

onMounted(() => loadThreshold())

// ✅ Load threshold using $api
async function loadThreshold() {
  try {
    const res = await $api(`thresholds/${tableName.value}`, {
      method: 'GET',
      onResponseError({ response }) {
        throw new Error(response._data?.error || 'Failed to load threshold.')
      },
    })

    const target = res.find((t) => t.id === id)
    if (!target) throw new Error('Threshold not found')

    const key = route.query.key
    const metric = target[key]
    thresholdKey.value = key
    description.value = metric?.description || 'No description available'

    weekValues.value = Object.entries(metric?.value || {}).map(([w, v]) => ({
      week: parseInt(w.replace('week', '')),
      value: v,
      error: false,
      errorMsg: '',
    }))
  } catch (err) {
    console.error('❌ Failed to load threshold:', err.message)
  }
}

// ✅ Validation for mixed value types
function validateValue(item) {
  const val = item.value
  const isTimeString = typeof val === 'string' && /[h:m]/i.test(val)
  if (isTimeString) {
    item.error = false
    item.errorMsg = ''
    return
  }

  const num = Number(val)
  if (isNaN(num)) {
    item.error = true
    item.errorMsg = 'Value must be numeric or valid time format.'
  } else if (num < 0) {
    item.error = true
    item.errorMsg = 'Value cannot be negative.'
  } else {
    item.error = false
    item.errorMsg = ''
  }
}

// ✅ Save changes with $api PUT
async function saveChanges() {
  try {
    let hasError = false
    weekValues.value.forEach((item) => {
      validateValue(item)
      if (item.error) hasError = true
    })

    if (hasError) {
      alert('Please fix invalid values before saving.')
      return
    }

    saving.value = true

    const updatedValue = {}
    weekValues.value.forEach((entry) => {
      const val = entry.value
      updatedValue[`week${entry.week}`] =
        typeof val === 'string' && /[h:m]/i.test(val) ? val : Number(val)
    })

    const payload = {
      [thresholdKey.value]: {
        value: updatedValue,
        description: description.value,
      },
    }

    await $api(`thresholds/${tableName.value}/${id}`, {
      method: 'PUT',
      body: payload,
      onResponseError({ response }) {
        throw new Error(response._data?.error || 'Failed to update threshold.')
      },
    })

    snackbar.value = true
    setTimeout(() => router.back(), 1000)
  } catch (err) {
    console.error('❌ Failed to save threshold:', err.message)
    alert('An error occurred while saving. Please try again.')
  } finally {
    saving.value = false
  }
}

// Display helpers
const formattedTableName = computed(() =>
  tableName.value ? capitalizeFirstLetter(tableName.value) : 'Unknown'
)
const formattedKey = computed(() => formatKey(thresholdKey.value))

function formatKey(str) {
  if (!str) return ''
  return str
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (s) => s.toUpperCase())
}

function capitalizeFirstLetter(str) {
  return str ? str.charAt(0).toUpperCase() + str.slice(1) : ''
}
</script>

<style scoped>
.v-card-title {
  letter-spacing: 0.3px;
}
.v-card-subtitle {
  letter-spacing: 0.2px;
}
</style>
