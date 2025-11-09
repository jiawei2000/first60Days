// services/assistantUsersService.js
const axios = require('axios');
require('dotenv').config();

async function askUsers(question) {
  const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
  console.log('[AssistantUsers] Key (partial):', OPENAI_API_KEY?.slice(0, 10));

  const prompt = `
You are an assistant converting natural language questions into Firestore filter queries
for the USERS collection.

Collection: "users"
Fields:
- email (string)
- password (string)
- phoneNo (string)
- username (string)
- createdAt (timestamp)
- lastLoginAt (timestamp)
- deletedAt (timestamp)
- permissionID (string)
- relation (string or null)
- fcmTokens (array)
- name (string)
- trainerID (string or null)
- createdByAdminID (string or null)

Given a question, respond ONLY with a JSON like:
{
  "collection": "users",
  "filters": [
    { "field": "trainerID", "op": "!=", "value": null },
    { "field": "createdAt", "op": ">=", "value": "2025-01-01T00:00:00Z" }
  ],
  "sort": { "field": "createdAt", "direction": "desc" },
  "limit": 50
}

Question: "${question}"
`;

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

  const text = response.data.choices[0].message.content;
  const jsonStart = text.indexOf('{');
  const json = JSON.parse(text.slice(jsonStart));
  return json;
}

module.exports = { askUsers };
