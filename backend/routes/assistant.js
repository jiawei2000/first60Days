const express = require('express');
const router = express.Router();

// Import the three controller handlers
const {
  handleBabyHealthQuery,
  handleUserQuery,
  handleTrainerQuery,
} = require('../controllers/assistantController');

// 👶 Baby GPT Query Endpoint
router.post('/babies/query/:id', handleBabyHealthQuery);

// 👨‍👩‍👧 User GPT Query Endpoint
router.post('/users/query', handleUserQuery);

// 🧑‍🏫 Trainer GPT Query Endpoint
router.post('/trainers/query', handleTrainerQuery);

module.exports = router;
