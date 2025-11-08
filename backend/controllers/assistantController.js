const admin = require('firebase-admin');
const { askGpt } = require('../services/gptQueryService');
const { Timestamp } = require('firebase-admin/firestore');

async function handleQuery(req, res) {
  const { question } = req.body;

  if (!question) {
    return res.status(400).json({ error: 'Missing question' });
  }

  try {
    // Get interpreted structure from GPT
    const interpreted = await askGpt(question);
    const db = admin.firestore();
    let q = db.collection(interpreted.collection);

    // Fields considered timestamp-based
    const timestampFields = [
  'dob', 'createdAt', 'deletedAt', 'expectedDueDate', 'lastLoginAt'
];


    // --- Step 1: Apply only the first date range filter (Firestore-friendly)
    let firestoreFilter = interpreted.filters?.find(f => timestampFields.includes(f.field));

    if (firestoreFilter) {
      let val = firestoreFilter.value;
      if (
        val !== null &&
        typeof val === 'string' &&
        !isNaN(Date.parse(val))
      ) {
        val = Timestamp.fromDate(new Date(val));
      }
      q = q.where(firestoreFilter.field, firestoreFilter.op, val);
    }

    // --- Step 2: Limit results to a reasonable number
    const limit = interpreted.limit || 100;
    q = q.limit(limit);

    // --- Step 3: Fetch documents from Firestore
    const snapshot = await q.get();
    let results = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // --- Step 4: Apply in-memory filtering (no Firestore index needed)
    for (const filter of interpreted.filters || []) {
      const field = filter.field;
      const op = filter.op;
      const val = filter.value;

      results = results.filter(doc => {
        const docVal = doc[field];

        // Handle timestamp comparison
        if (timestampFields.includes(field) && docVal?._seconds) {
          const docDate = new Date(docVal._seconds * 1000);
          const filterDate = new Date(val);

          if (op === '>=')
            return docDate >= filterDate;
          if (op === '<=')
            return docDate <= filterDate;
          if (op === '<')
            return docDate < filterDate;
          if (op === '>')
            return docDate > filterDate;
        }

        // Handle string comparison (like gender)
        if (op === '==' && typeof docVal === 'string' && typeof val === 'string') {
          return docVal.toLowerCase() === val.toLowerCase();
        }

        return true;
      });
    }

    // --- Step 5: Return filtered results
    res.json({ interpreted, results });

  } catch (err) {
    console.error('Error in assistantController:', err);
    res.status(500).json({
      error: 'Something went wrong',
      details: err.message
    });
  }
}

module.exports = { handleQuery };
