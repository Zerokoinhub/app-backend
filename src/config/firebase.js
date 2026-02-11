const admin = require("firebase-admin");

if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
  console.error("FIREBASE_SERVICE_ACCOUNT is not set!");
  process.exit(1);
}

let serviceAccount;

try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  // Replace literal \n with actual newlines
  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, "\n");
} catch (err) {
  console.error("Failed to parse Firebase service account key:", err);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "zerokoin-705c5.firebasestorage.app"  // ✅ YEH ADD KAR!
});

console.log("Firebase Admin initialized successfully");

module.exports = { admin };
