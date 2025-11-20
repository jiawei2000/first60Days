<template>
  <VCard title="Threshold Settings">
    <VCardText>
      <!-- Tabs -->
      <VTabs v-model="activeTab" background-color="transparent" grow>
        <VTab value="daily">Daily</VTab>
        <VTab value="weekly">Weekly</VTab>
      </VTabs>

      <VDivider class="my-4" />

      <VWindow v-model="activeTab">
        <!-- Daily -->
        <VWindowItem value="daily">
          <VDataTable
            :headers="headers"
            :items="dailyRows"
            :items-per-page="10"
            class="elevation-1"
          >
            <template #item.key="{ item }">
              <span class="font-weight-medium">{{ formatKey(item.key) }}</span>
            </template>

            <template #item.description="{ item }">
              <VTooltip :text="item.description" max-width="420">
                <template #activator="{ props }">
                  <span v-bind="props" class="text-truncate d-inline-block" style="max-width: 520px;">
                    {{ item.description }}
                  </span>
                </template>
              </VTooltip>
            </template>

            <template #item.action="{ item }">
              <VBtn
                color="primary"
                variant="tonal"
                size="small"
                @click="goEdit('daily', item.key)"
              >
                Edit
              </VBtn>
            </template>
          </VDataTable>
        </VWindowItem>

        <!-- Weekly -->
        <VWindowItem value="weekly">
          <VDataTable
            :headers="headers"
            :items="weeklyRows"
            :items-per-page="10"
            class="elevation-1"
          >
            <template #item.key="{ item }">
              <span class="font-weight-medium">{{ formatKey(item.key) }}</span>
            </template>

            <template #item.description="{ item }">
              <VTooltip :text="item.description" max-width="420">
                <template #activator="{ props }">
                  <span v-bind="props" class="text-truncate d-inline-block" style="max-width: 520px;">
                    {{ item.description }}
                  </span>
                </template>
              </VTooltip>
            </template>

            <template #item.action="{ item }">
              <VBtn
                color="primary"
                variant="tonal"
                size="small"
                @click="goEdit('weekly', item.key)"
              >
                Edit
              </VBtn>
            </template>
          </VDataTable>
        </VWindowItem>
      </VWindow>
    </VCardText>
  </VCard>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

definePage({ meta: { adminOnly: true } })

const router = useRouter()
const activeTab = ref('daily')

const headers = [
  { title: 'Key', key: 'key', align: 'start', sortable: false },
  { title: 'Description', key: 'description', align: 'start', sortable: false },
  { title: 'Action', key: 'action', align: 'center', sortable: false },
]

const dailyId = ref(null)
const weeklyId = ref(null)
const dailyRows = ref([])
const weeklyRows = ref([])

onMounted(() => loadThresholds())

async function loadThresholds() {
  try {
    const [dailyRes, weeklyRes] = await Promise.all([
      $api('thresholds/daily', {
        method: 'GET',
        onResponseError({ response }) {
          throw new Error(response._data?.error || 'Failed to load daily thresholds.')
        },
      }),
      $api('thresholds/weekly', {
        method: 'GET',
        onResponseError({ response }) {
          throw new Error(response._data?.error || 'Failed to load weekly thresholds.')
        },
      }),
    ])

    // Assign IDs
    dailyId.value = Array.isArray(dailyRes) && dailyRes[0]?.id ? dailyRes[0].id : null
    weeklyId.value = Array.isArray(weeklyRes) && weeklyRes[0]?.id ? weeklyRes[0].id : null

    // Convert objects to rows
    dailyRows.value = toRows(dailyRes)
    weeklyRows.value = toRows(weeklyRes)
  } catch (e) {
    console.error('❌ Failed to fetch thresholds:', e.message)
  }
}

function toRows(json) {
  if (!Array.isArray(json) || !json.length) return []
  const obj = json[0]
  return Object.keys(obj)
    .filter((k) => k !== 'id')
    .map((k) => ({
      key: k,
      description: obj[k]?.description || 'No description available',
    }))
}

function formatKey(key) {
  return key
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (s) => s.toUpperCase())
}

function goEdit(type, key) {
  const id = type === 'daily' ? dailyId.value : weeklyId.value
  if (!id) {
    console.error('Missing threshold id for', type)
    return
  }
  router.push({
    path: `/admin/threshold/edit-threshold/${id}`,
    query: { type, key },
  })
}
</script>

<style scoped>
.text-truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
