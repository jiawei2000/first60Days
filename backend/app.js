const express = require('express')
const app = express()
const cors = require('cors')
const dotenv = require('dotenv')
const morgan = require('morgan')

const userRoutes = require('./routes/userRoutes');
const babyRoutes = require('./routes/babyRoutes');
const journalEntryRoutes = require('./routes/journalRoutes');
// require('./jobs/batchJobs');
// require('./jobs/notifications');

// Load env variables
dotenv.config()

app.use(cors())
app.use(express.json())
app.use(morgan('tiny'))

// Define routes
app.get('/', (req, res) => {
  res.send('Hello World!')
})

//routes 
app.use('/api/users', userRoutes);
app.use('/api/babies', babyRoutes);
app.use('/api/journalEntries', journalEntryRoutes);
app.use('/api/entryPlanner', entryPlannerRouters);


// Error handling middleware
app.use((req, res, next) => {
  res.status(404).send('Not Found')
})

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).send('Something went wrong!')
})

module.exports = app; 