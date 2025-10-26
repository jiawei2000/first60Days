<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()
const userData = useCookie('userData')

function handleLogout() {
    useCookie('accessToken').value = null
    useCookie('userData').value = null
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
                    <VListItemSubtitle>{{ userData?.role || 'Role Error' }}</VListItemSubtitle>
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
