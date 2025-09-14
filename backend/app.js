const express = require('express')
const app = express()
const cors = require('cors')
const dotenv = require('dotenv')
const morgan = require('morgan')

// const authRouter = require('./functions/auth');
// const { router: authRouter, authenticateToken } = require('./functions/auth');
// const entryRouter = require('./functions/entry');
// const babyProfileRouter = require('./functions/babyProfile');
// const permissionRouter = require('./functions/permission');
const userRoutes = require('./routes/userRoutes');
const babyRoutes = require('./routes/babyRoutes');
const journalEntryRoutes = require('./routes/journalRoutes');

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
app.use('/users', userRoutes);
app.use('/babies', babyRoutes);
app.use('/journalEntries', journalEntryRoutes);



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