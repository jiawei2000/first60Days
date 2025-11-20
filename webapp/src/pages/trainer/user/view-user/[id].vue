        <template>
        <VCard title="Babies for User ...">
        <VCardText>
            <VDataTable :headers="headers" :items="data" :items-per-page="10">
            <!-- Actions -->
            <template #item.actions="{ item }">
                <div class="d-flex gap-1">
                <!-- Edit Baby -->
                <IconBtn @click="viewBaby(item)">
                    <VIcon icon="bx-calendar" />
                </IconBtn>

                <!-- View Stats -->
                <IconBtn @click="statsBaby(item)">
                    <VIcon icon="bx-bar-chart" />
                </IconBtn>
                </div>
            </template>
            </VDataTable>
        </VCardText>
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
import { useRoute, useRouter } from "vue-router"

definePage({
    meta: {
        trainerOnly: true,
    },
})

const route = useRoute()
const router = useRouter()

const isSnackBarVisible = ref(false)
const snackBarMessage = ref("")

const data = ref([])

const headers = [
    { title: "Name", key: "name" },
    { title: "Gender", key: "gender" },
    { title: "Height(cm)", key: "height" },
    { title: "Weight(kg)", key: "weight" },
    { title: "Term", key: "term" },
    { title: "Health Conditions", key: "healthConditions" },
    { title: "Actions", value: "actions", sortable: false },
]

onMounted(async () => {
    await getBabyListByUserId(route.params.id)
})

async function getBabyListByUserId(userId) {
    try {
        const res = await $api('trainers/users/' + userId + '/babies', {
            method: 'GET',
            onResponseError({ response }) {
                throw new Error(response._data)
            }
        })

        data.value = res.babies.map(baby => ({
            id: baby.id,
            name: baby.name,
            gender: baby.gender,
            height: baby.height,
            weight: baby.weight,
            term: baby.term,
            healthConditions: baby.healthConditions,
        }))
    } catch (error) {
        snackBarMessage.value = error
        isSnackBarVisible.value = true
    }
}

function viewBaby(item) {
    router.push('/trainer/user/view-baby/' + item.id)
}

function statsBaby(item) {
  router.push(`/trainer/user/view-stats/`+ item.id)
}
</script>