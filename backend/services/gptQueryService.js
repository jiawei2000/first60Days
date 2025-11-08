const axios = require('axios');
require('dotenv').config();

async function askOpenAI(question) {
  const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
  console.log('OpenAI Key (partial):', OPENAI_API_KEY?.slice(0, 10));

  const prompt = `
You are an assistant converting natural language questions into Firestore filter queries.

The Firestore collection is called "babies". Each document has these fields:
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

Question: "${question}"

Respond ONLY with clean JSON like:
{
  "collection": "babies",
  "filters": [
    { "field": "dob", "op": "<", "value": "2025-08-01" }
  ],
  "limit": 50
}
`;

  const response = await axios.post(
    'https://api.openai.com/v1/chat/completions',
    {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2
    },
    {
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 60000
    }
  );

  const text = response.data.choices[0].message.content;
  const jsonStart = text.indexOf('{');
  const json = JSON.parse(text.slice(jsonStart));
  return json;
}

module.exports = { askGpt: askOpenAI };
