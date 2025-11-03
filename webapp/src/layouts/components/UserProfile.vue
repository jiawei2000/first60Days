<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const userData = useCookie('userData')
const accessToken = useCookie('accessToken')
const displayName = computed(() => {
  const data = userData.value
  return (data?.name || data?.username || 'User')
})

function decodeJwt(token) {
  try {
    const base64 = token.split('.')[1]
    return JSON.parse(atob(base64))
  } catch {
    return null
  }
}

const roleLabel = computed(() => {
    const cookieRole = userData.value?.role
    const jwtRole = accessToken.value ? decodeJwt(accessToken.value)?.role : null
    const role = cookieRole || jwtRole
    if (!role)
        return 'Role Error'
    return `${role.charAt(0).toUpperCase()}${role.slice(1)}`
})

const profilePath = computed(() => '/profile')

function handleLogout() {
    let tempRole = userData.value?.role
    useCookie('accessToken').value = null
    useCookie('userData').value = null
    if (tempRole === 'trainer')
        router.push('/trainer/login')
    else
        router.push('/admin/login')
}

// Add this function to navigate to profile
function goToProfile() {
    router.push(profilePath.value)
}
</script>

<template>
    <VAvatar class="cursor-pointer" color="primary" variant="tonal">
        <VIcon class="" icon="bx-user" size="20" />

        <VMenu activator="parent" width="230" location="bottom end" offset="14px">
            <VList>
                <!-- Make this entire section clickable to go to profile -->
                <VListItem @click="goToProfile" class="cursor-pointer">
                    <template #prepend>
                        <VListItemAction start>
                            <VAvatar color="primary" variant="tonal">
                                <VIcon class="" icon="bx-user" size="20" />
                            </VAvatar>
                        </VListItemAction>
                    </template>

                    <VListItemTitle class="font-weight-semibold">
                        {{ displayName }}
                    </VListItemTitle>
                    <VListItemSubtitle>{{ roleLabel }}</VListItemSubtitle>
                </VListItem>

                <VDivider class="my-2" />

                <!-- Logout option -->
                <VListItem @click="handleLogout">
                    <template #prepend>
                        <VIcon class="me-2" icon="bx-log-out" size="22" />
                    </template>
                    <VListItemTitle>Logout</VListItemTitle>
                </VListItem>
            </VList>
        </VMenu>
    </VAvatar>
</template>
