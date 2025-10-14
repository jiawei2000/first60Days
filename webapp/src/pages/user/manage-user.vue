<template>
    <div>
        <VCard title="Manage Users">
            <VCardText>
                <VDataTable :headers="headers" :items="data" :items-per-page="10">
                </VDataTable>
            </VCardText>
        </VCard>
    </div>
</template>

<script setup>
import { ref } from "vue"


const headers = [
    { title: "UserName", key: "username" },
    { title: "Email", key: "email" },
    { title: "Phone No", key: "phone" },
    { title: "Last Login", key: "lastLogin" },
    { title: "Created At", key: "createdAt" },
]

const data = ref([
    {
        username: "Alice Johnson",
        email: "alice.johnson@example.com",
        phone: "91234567",
        lastLogin: "2024-05-10 14:32",
        createdAt: "2023-11-21",
    },
    {
        username: "Benjamin Lee",
        email: "ben.lee@example.com",
        phone: "91234568",
        lastLogin: "2024-05-08 09:17",
        createdAt: "2023-12-04",
    },
    {
        username: "Chloe Martinez",
        email: "chloe.martinez@example.com",
        phone: "91234569",
        lastLogin: "2024-05-11 21:05",
        createdAt: "2024-01-15",
    },
    {
        username: "Daniel Patel",
        email: "dan.patel@example.com",
        phone: "91234570",
        lastLogin: "2024-05-07 16:48",
        createdAt: "2023-09-30",
    },
    {
        username: "Emily Chen",
        email: "emily.chen@example.com",
        phone: "91234571",
        lastLogin: "2024-05-09 11:24",
        createdAt: "2024-02-10",
    },
]);

</script>
