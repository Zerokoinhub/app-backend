// config/firebase-admin.js
const admin = require('firebase-admin');

// Check if Firebase Admin is already initialized
if (!admin.apps.length) {
  try {
    // Method 1: Using service account from environment variable (recommended)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 
                      `${serviceAccount.project_id}.appspot.com`
      });
    } 
    // Method 2: Using individual environment variables
    else if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
        }),
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 
                      `${process.env.FIREBASE_PROJECT_ID}.appspot.com`
      });
    } else {
      console.error('❌ Firebase Admin: No credentials found in environment variables');
      console.error('   Please set either FIREBASE_SERVICE_ACCOUNT or FIREBASE_PROJECT_ID');
    }
    
    console.log('✅ Firebase Admin initialized successfully');
    console.log('   Storage Bucket:', admin.storage().bucket().name);
    
  } catch (error) {
    console.error('❌ Firebase Admin initialization failed:', error.message);
    console.error('   Stack:', error.stack);
  }
}

module.exports = admin;