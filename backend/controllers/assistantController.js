const admin = require('firebase-admin');
const { Timestamp } = require('firebase-admin/firestore');

// Import the 3 separate GPT query services
const { askBabies } = require('../services/gptQueryServiceBaby');
const { askUsers } = require('../services/gptQueryServiceUsers');
const { askTrainers } = require('../services/gptQueryServiceTrainers');

// Common timestamp fields used for Firestore filtering
const timestampFields = [
  'dob', 'createdAt', 'deletedAt', 'expectedDueDate', 'lastLoginAt'
];

/**
 * 🔹 Shared query execution logic (runs after GPT interpretation)
 */
async function executeQuery(interpreted) {
  const db = admin.firestore();
  let q = db.collection(interpreted.collection);

  // Step 1: Apply only one Firestore-native filter (timestamp-based if available)
  const firestoreFilter = interpreted.filters?.find(f => timestampFields.includes(f.field));
  if (firestoreFilter) {
    let val = firestoreFilter.value;
    if (val !== null && typeof val === 'string' && !isNaN(Date.parse(val))) {
      val = Timestamp.fromDate(new Date(val));
    }
    q = q.where(firestoreFilter.field, firestoreFilter.op, val);
  }

  // Step 2: Apply limit
  const limit = interpreted.limit || 100;
  q = q.limit(limit);

  // Step 3: Fetch documents
  const snapshot = await q.get();
  let results = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  }));

  // Step 4: Apply additional filters in-memory
  for (const filter of interpreted.filters || []) {
    const { field, op, value: val } = filter;
    results = results.filter(doc => {
      const docVal = doc[field];

      // Handle timestamp comparison
      if (timestampFields.includes(field) && docVal?._seconds) {
        const docDate = new Date(docVal._seconds * 1000);
        const filterDate = new Date(val);

        if (op === '>=') return docDate >= filterDate;
        if (op === '<=') return docDate <= filterDate;
        if (op === '<') return docDate < filterDate;
        if (op === '>') return docDate > filterDate;
      }

      // Handle equality string comparison
      if (op === '==' && typeof docVal === 'string' && typeof val === 'string') {
        return docVal.toLowerCase() === val.toLowerCase();
      }

      return true;
    });
  }

  return results;
}

/**
 * 🍼 Baby Query Handler
 */
async function handleBabyQuery(req, res) {
  const { question } = req.body;
  if (!question) return res.status(400).json({ error: 'Missing question' });

  try {
    const interpreted = await askBabies(question);
    const results = await executeQuery(interpreted);
    res.json({ interpreted, results });
  } catch (err) {
    console.error('❌ Baby Query Error:', err);
    res.status(500).json({ error: err.message });
  }
}

/**
 * 👨‍👩‍👧 User Query Handler
 */
async function handleUserQuery(req, res) {
  const { question } = req.body;
  if (!question) return res.status(400).json({ error: 'Missing question' });

  try {
    const interpreted = await askUsers(question);
    const results = await executeQuery(interpreted);
    res.json({ interpreted, results });
  } catch (err) {
    console.error('❌ User Query Error:', err);
    res.status(500).json({ error: err.message });
  }
}

/**
 * 🧑‍🏫 Trainer Query Handler
 */
async function handleTrainerQuery(req, res) {
  const { question } = req.body;
  if (!question) return res.status(400).json({ error: 'Missing question' });

  try {
    const interpreted = await askTrainers(question);
    const results = await executeQuery(interpreted);
    res.json({ interpreted, results });
  } catch (err) {
    console.error('❌ Trainer Query Error:', err);
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  handleBabyQuery,
  handleUserQuery,
  handleTrainerQuery,
};
