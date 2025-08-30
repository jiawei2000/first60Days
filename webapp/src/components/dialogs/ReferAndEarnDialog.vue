<script setup lang="ts">
import { themeConfig } from '@themeConfig'

interface Props {
  isDialogVisible: boolean
}

interface Emit {
  (e: 'update:isDialogVisible', val: boolean): void
}

const props = defineProps<Props>()

const emit = defineEmits<Emit>()

const dialogVisibleUpdate = (val: boolean) => {
  emit('update:isDialogVisible', val)
}

const referAndEarnSteps = [
  {
    icon: 'bx-message-square-dots',
    title: 'Send Invitation 👍🏻',
    subtitle: 'Send your referral link to your friend',
  },
  {
    icon: 'bx-detail',
    title: 'Registration 😎',
    subtitle: 'Let them register to our services',
  },
  {
    icon: 'bx-gift',
    title: 'Free Trial  🎉',
    subtitle: 'Your friend will get 30 days free trial',
  },
]
</script>

<template>
  <VDialog
    :model-value="props.isDialogVisible"
    :width="$vuetify.display.smAndDown ? 'auto' : 800"
    @update:model-value="dialogVisibleUpdate"
  >
    <!-- 👉 Dialog close btn -->
    <DialogCloseBtn @click="$emit('update:isDialogVisible', false)" />

    <VCard class="pa-2 pa-sm-10">
      <VCardText>
        <h4 class="text-h4 text-center mb-2">
          Refer & Earn
        </h4>
        <p class="text-body-1 mb-12 text-center">
          Invite your friend to <span class="text-capitalize">{{ themeConfig.app.title }}</span>, if they sign up, you and your friend will get 30 days free trial
        </p>

        <VRow class="text-center ">
          <VCol
            v-for="step in referAndEarnSteps"
            :key="step.title"
            cols="12"
            sm="4"
          >
            <VAvatar
              variant="tonal"
              size="88"
              color="primary"
              rounded
            >
              <VIcon
                size="40"
                :icon="step.icon"
              />
            </VAvatar>

            <h5 class="text-h5 mt-4 mb-2">
              {{ step.title }}
            </h5>
            <div class="text-body-1">
              {{ step.subtitle }}
            </div>
          </VCol>
        </VRow>

        <VDivider class="mt-12 mb-6" />

        <h5 class="text-h5 mb-6">
          Invite your friends
        </h5>

        <VForm
          class="d-flex align-center flex-wrap gap-4"
          @submit.prevent="() => {}"
        >
          <AppTextField
            placeholder="johnDoe@gmail.com"
            label="Enter your friend's email address and invite them to join Sneat 😍"
          />

          <VBtn
            class="align-self-end"
            type="submit"
          >
            Send
          </VBtn>
        </VForm>

        <h5 class="text-h5 my-6">
          Share the referral link
        </h5>

        <VForm
          class="d-flex align-center flex-wrap gap-4"
          @submit.prevent="() => {}"
        >
          <AppTextField
            placeholder="http://themeselection.link"
            label="You can also copy and send it or share it on your social media. 🚀"
            class="refer-link-input"
          />

          <div class="d-flex align-self-end gap-1">
            <VBtn
              icon
              class="rounded"
              color="#3B5998"
              size="38"
            >
              <VIcon
                color="white"
                icon="bx-bxl-facebook"
                size="22"
              />
            </VBtn>

            <VBtn
              icon
              class="rounded"
              color="#55ACEE"
              size="38"
            >
              <VIcon
                color="white"
                icon="bx-bxl-twitter"
                size="22"
              />
            </VBtn>

            <VBtn
              icon
              class="rounded"
              color="#007BB6"
              size="38"
            >
              <VIcon
                color="white"
                icon="bx-bxl-linkedin"
                size="22"
              />
            </VBtn>
          </div>
        </VForm>
      </VCardText>
    </VCard>
  </VDialog>
</template>

<style lang="scss">
.refer-link-input {
  .v-field--appended {
    padding-inline-end: 0;
  }
}
</style>
