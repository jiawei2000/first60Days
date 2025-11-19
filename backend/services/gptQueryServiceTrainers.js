// services/assistantTrainersService.js
const axios = require('axios');
require('dotenv').config();

/**
 * Converts natural language trainer-related questions
 * into structured Firestore query JSON.
 */
async function askTrainers(question) {
  const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
  console.log('[AssistantTrainers] Key (partial):', OPENAI_API_KEY?.slice(0, 10));

  const prompt = `
You are an assistant that converts natural language questions about TRAINERS
into Firestore filter queries.

Collection: "trainers"
Fields:
- username (string)
- email (string)
- password (string)
- name (string)
- createdAt (timestamp)
- deletedAt (timestamp or null)
- lastLoginAt (timestamp or null)
- createdByAdminID (string or null)

Return ONLY a JSON response in the following format:
{
  "collection": "trainers",
  "filters": [
    { "field": "createdAt", "op": ">=", "value": "2025-01-01T00:00:00Z" },
    { "field": "deletedAt", "op": "==", "value": null }
  ],
  "sort": { "field": "createdAt", "direction": "desc" },
  "limit": 50
}

Do not include explanations or extra text.
Question: "${question}"
`;

  try {
    const response = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.2,
      },
      {
        headers: {
          Authorization: `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 60000,
      }
    );

    const text = response.data.choices[0].message.content.trim();
    const jsonStart = text.indexOf('{');
    const json = JSON.parse(text.slice(jsonStart));
    return json;
  } catch (err) {
    console.error('❌ Trainer AI service error:', err.message);
    throw new Error('Failed to interpret trainer question');
  }
}

module.exports = { askTrainers };
