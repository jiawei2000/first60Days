export default [
    //Admin Pages
    {
        title: 'Home',
        to: { name: 'admin' },
        icon: { icon: 'bx-home-alt' },
        viewBy: 'admin'
    },
    {
        title: 'Manage User',
        to: { name: 'admin-user-manage-user' },
        icon: { icon: 'bx-user' },
        viewBy: 'admin'
    },
    {
        title: 'Manage Trainers',
        to: { name: 'admin-trainer-manage-trainer' },
        icon: { icon: 'bx-user' },
        viewBy: 'admin'
    },
    // Trainer Pages
    {
        title: 'Home',
        to: { name: 'trainer' },
        icon: { icon: 'bx-home-alt' },
        viewBy: 'trainer'
    },
    {
        title: 'Manage User',
        to: { name: 'trainer-user-manage-users' },
        icon: { icon: 'bx-user' },
        viewBy: 'trainer'
    }
]
