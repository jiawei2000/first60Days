const { initializeApp, applicationDefault, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

require('dotenv').config();

// Build service account object from environment variables (if present)
const hasServiceAccountEnv =
  process.env.FIREBASE_PROJECT_ID &&
  process.env.FIREBASE_CLIENT_EMAIL &&
  process.env.FIREBASE_PRIVATE_KEY;

let app;

if (!getApps().length) {
  if (hasServiceAccountEnv) {
    // Localhost
    const serviceAccount = {
      type: process.env.FIREBASE_TYPE,
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: process.env.FIREBASE_AUTH_URI,
      token_uri: process.env.FIREBASE_TOKEN_URI,
      auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
      client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
      universe_domain: process.env.FIREBASE_UNIVERSE_DOMAIN,
    };

    app = initializeApp({
      credential: cert(serviceAccount),
    });
  } else {
    // Deployment
    app = initializeApp({
      credential: applicationDefault(),
    });
  }
}

const db = getFirestore();
module.exports = db;