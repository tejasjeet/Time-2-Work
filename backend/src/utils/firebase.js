const { env } = require('../config/env');

let adminApp = null;

function getFirebaseAdmin() {
  if (!env.firebaseEnabled) return null;
  if (adminApp) return adminApp;
  try {
    const admin = require('firebase-admin');
    if (admin.apps.length) {
      adminApp = admin.app();
      return adminApp;
    }
    const creds =
      env.firebaseClientEmail && env.firebasePrivateKey
        ? {
            credential: admin.credential.cert({
              projectId: env.firebaseProjectId,
              clientEmail: env.firebaseClientEmail,
              privateKey: env.firebasePrivateKey,
            }),
          }
        : undefined;
    adminApp = admin.initializeApp(creds);
    return adminApp;
  } catch (err) {
    console.warn('Firebase admin init failed:', err.message);
    return null;
  }
}

async function verifyFirebaseIdToken(idToken) {
  const app = getFirebaseAdmin();
  if (!app) {
    const err = new Error('Firebase is not enabled');
    err.status = 501;
    throw err;
  }
  const admin = require('firebase-admin');
  return admin.auth().verifyIdToken(idToken);
}

module.exports = { getFirebaseAdmin, verifyFirebaseIdToken };
