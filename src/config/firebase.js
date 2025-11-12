const admin = require("firebase-admin");

let serviceAccount = {};
try {
  if (!process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY is not set!");
  }
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
} catch (error) {
  console.error("Failed to parse Firebase service account key:", error.message);
  process.exit(1); // Stop app since Firebase is required
}

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log("Firebase Admin initialized successfully");
} catch (error) {
  console.error("Firebase initialization error:", error);
  process.exit(1);
}

module.exports = { admin };
