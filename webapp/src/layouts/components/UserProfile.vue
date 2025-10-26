<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const userData = useCookie('userData')

const roleLabel = computed(() => {
    const role = userData.value?.role
    if (!role)
        return 'Role Error'
    // Capitalize first letter of role
    return `${role.charAt(0).toUpperCase()}${role.slice(1)}`
})

function handleLogout() {
    let tempRole = userData.value?.role
    useCookie('accessToken').value = null
    useCookie('userData').value = null
    if (tempRole === 'trainer')
        router.push('/trainer/login')
    else
        router.push('/admin/login')
}
</script>

<template>
    <VAvatar class="cursor-pointer" color="primary" variant="tonal">
        <VIcon class="" icon="bx-user" size="20" />

        <VMenu activator="parent" width="230" location="bottom end" offset="14px">
            <VList>
                <VListItem>
                    <template #prepend>
                        <VListItemAction start>
                            <VAvatar color="primary" variant="tonal">
                                <VIcon class="" icon="bx-user" size="20" />
                            </VAvatar>
                        </VListItemAction>
                    </template>

                    <VListItemTitle class="font-weight-semibold">
                        {{ userData?.name || 'User Error' }}
                    </VListItemTitle>
                    <VListItemSubtitle>{{ roleLabel }}</VListItemSubtitle>
                </VListItem>

                <VDivider class="my-2" />

                <!-- 👉 Logout -->
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
