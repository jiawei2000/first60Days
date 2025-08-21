const express = require('express')
const app = express()
const cors = require('cors')
const dotenv = require('dotenv')
const morgan = require('morgan')
const db = require('./database');

// Load env variables
dotenv.config()

app.use(cors())
app.use(express.json())
app.use(morgan('tiny'))

// Define routes
app.get('/', (req, res) => {
    res.send('Hello World!')
})

//get all users
app.get('/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = [];
    snapshot.forEach(doc => users.push({ id: doc.id, ...doc.data() }));
    // console.log(users);
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


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