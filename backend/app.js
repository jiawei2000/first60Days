const express = require('express')
const app = express()
const cors = require('cors')
const dotenv = require('dotenv')
const morgan = require('morgan')

// Load env variables
dotenv.config()

app.use(express.json({ limit: '10mb' })); // or higher if needed
app.use(cors())
// app.use(express.json())
app.use(morgan('tiny'))

const thresholdRoutes = require('./routes/thresholdRoutes');
const adminRoutes = require('./routes/adminRoutes');
const trainerRoutes = require('./routes/trainerRoutes');
const userRoutes = require('./routes/userRoutes');

const babyRoutes = require('./routes/babyRoutes');
const journalEntryRoutes = require('./routes/journalRoutes');
const entryPlannerRouters = require('./routes/entryPlannerRoutes');
const heightWeightRoutes = require('./routes/weeklyHWRoutes');

const notificationRoutes = require('./routes/notificationRoutes');

const statisticsRoutes = require('./routes/statisticsRoutes');
const excelRoutes = require('./routes/excelRoutes');

// require('./jobs/batchJobs');
// require('./jobs/topicNotifications');
// require('./jobs/personalNotifications');
// require('./jobs/processStatistics');

// Define routes
app.get('/', (req, res) => {
  res.send('Hello World!')
})

//routes 
app.use('/api/admins', adminRoutes);
app.use('/api/trainers', trainerRoutes);
app.use('/api/users', userRoutes);

app.use('/api/babies', babyRoutes);
app.use('/api/updateHeightWeight', heightWeightRoutes);
app.use('/api/journalEntries', journalEntryRoutes);
app.use('/api/entryPlanner', entryPlannerRouters);
app.use('/api/notifications', notificationRoutes);

app.use('/api/statistics', statisticsRoutes);
app.use('/api/excel', excelRoutes);
app.use('/api/thresholds', thresholdRoutes);

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