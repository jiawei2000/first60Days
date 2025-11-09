// services/assistantBabiesService.js
const axios = require('axios');
require('dotenv').config();

async function askBabies(question) {
  const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
  console.log('[AssistantBabies] Key (partial):', OPENAI_API_KEY?.slice(0, 10));

  const prompt = `
You are an assistant that converts natural language questions about BABIES
into Firestore filter queries.

Collection: "babies"
Fields:
- name (string)
- dob (timestamp)
- createdAt (timestamp)
- deletedAt (timestamp or null)
- expectedDueDate (timestamp)
- term (number)
- weight (number)
- healthConditions (string)
- gender (string)
- height (number)
- vaccination (string)
- allergies (string)

Given a question, respond ONLY with a JSON like:
{
  "collection": "babies",
  "filters": [
    { "field": "gender", "op": "==", "value": "Female" },
    { "field": "deletedAt", "op": "==", "value": null }
  ],
  "sort": { "field": "dob", "direction": "asc" },
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

module.exports = { askBabies };
