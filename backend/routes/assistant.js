const express = require('express');
const router = express.Router();

// Import the three controller handlers
const {
  handleBabyQuery,
  handleUserQuery,
  handleTrainerQuery,
} = require('../controllers/assistantController');

// 👶 Baby GPT Query Endpoint
router.post('/babies/query', handleBabyQuery);

// 👨‍👩‍👧 User GPT Query Endpoint
router.post('/users/query', handleUserQuery);

// 🧑‍🏫 Trainer GPT Query Endpoint
router.post('/trainers/query', handleTrainerQuery);

module.exports = router;
