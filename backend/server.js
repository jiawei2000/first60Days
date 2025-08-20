const express = require('express')
const app = express()
const cors = require('cors')
const dotenv = require('dotenv')
const morgan = require('morgan')

// Load env variables
dotenv.config()

app.use(cors())
app.use(express.json())
app.use(morgan('tiny'))

// Define routes
app.get('/', (req, res) => {
    res.send('Hello World!')
})

// Error handling middleware
app.use((req, res, next) => {
    res.status(404).send('Not Found')
})

// Global error handler
app.use((err, req, res, next) => {
    console.error(err.stack)
    res.status(500).send('Something went wrong!')
})

// Start server
const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`)
})