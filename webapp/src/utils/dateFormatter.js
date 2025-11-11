// This function contains utility functions for formatting dates.

function formatSecondsToDateString(seconds) {
    if (!seconds) return "Invalid Date"
    const date = new Date(seconds * 1000)
    return date.toLocaleDateString()
}

export { formatSecondsToDateString }