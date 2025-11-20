<template>
  <VCard :title="cardTitle">
    <VCardText>
      
      <!-- Input Field -->
      <VTextField
        v-model="question"
        label="Ask a question about this baby's health"
        placeholder="e.g. Why is the baby crying so much?"
        clearable
      />

      <!-- Buttons Row -->
      <VRow class="mt-3" align="center">
        <VCol cols="auto">
          <VBtn
            color="primary"
            :loading="loading"
            @click="askAI"
          >
            Ask AI
          </VBtn>
        </VCol>

        <VCol cols="auto">
          <VBtn
            variant="tonal"
            color="grey"
            class="ml-4"
            @click="goBack"
          >
            ← Back to Babies List
          </VBtn>
        </VCol>
      </VRow>

      <!-- AI Response -->
      <VAlert
        v-if="answer"
        type="info"
        variant="outlined"
        class="mt-4"
      >
        <strong>AI Response:</strong><br />
        {{ answer }}
      </VAlert>

    </VCardText>
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
import { useRoute, useRouter } from 'vue-router'

definePage({
  meta: { trainerOnly: true },
})

const route = useRoute()
const router = useRouter()

const babyId = route.params.id

const cardTitle = "Baby Health AI Assistant"

const question = ref("")
const answer = ref("")
const loading = ref(false)

const isSnackBarVisible = ref(false)
const snackBarMessage = ref("")

async function askAI() {
  if (!question.value.trim()) {
    snackBarMessage.value = "Please enter a question."
    isSnackBarVisible.value = true
    return
  }

  loading.value = true
  answer.value = ""

  try {
    const res = await $api(`/assistant/babies/query/${babyId}`, {
      method: "POST",
      body: { question: question.value }
    })

    answer.value = res.answer
  } catch (err) {
    snackBarMessage.value = "Error fetching AI response."
    isSnackBarVisible.value = true
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push("/trainer/journal_entries/journal_entries")
}
</script>

<style scoped>
.cursor-pointer tr {
  cursor: pointer;
}
</style>
