const axios = require('axios');
const JournalService = require('./journalService'); // 👈 Local service
require('dotenv').config();

async function analyzeBabyHealth(babyId, question) {
  const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
  

  if (!babyId || !question) {
    throw new Error('Missing babyId or question');
  }

  // ✅ Fetch journal entries directly via service
  const journalEntries = await JournalService.getEntries(babyId);

  // 🧼 Clean feedType for better readability
  const cleanedEntries = journalEntries.map(entry => ({
    ...entry,
    feedType: Array.isArray(entry.feedType)
      ? entry.feedType.map(f => `${f.type} (${f.value} ${f.unit})`)
      : [],
  }));

  // 🧠 Prompt for OpenAI
  const prompt = `
You are a baby health analyzer. You will receive a list of baby journal entries.
Each entry contains information like feeding, sleeping, stool, and urine events.

Your job is to analyze the entries and answer a user's question using this data.
Be concise, insightful, and use bullet points if needed.

📊 Baby Journal Data:
${JSON.stringify(cleanedEntries.slice(-30), null, 2)}

❓ Question: ${question}
`;

  // 🎯 Call OpenAI
  const response = await axios.post(
    'https://api.openai.com/v1/chat/completions',
    {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
    },
    {
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: 60000,
    }
  );

  return response.data.choices?.[0]?.message?.content || 'No response.';
}

module.exports = { analyzeBabyHealth };
