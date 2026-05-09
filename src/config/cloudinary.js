const multer = require('multer');
const { admin } = require('./firebase');
const crypto = require('crypto');

// Use Firebase Storage
const uploadScreenshots = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }
});

const uploadToFirebase = async (file, userId) => {
  const bucket = admin.storage().bucket();
  const timestamp = Date.now();
  const random = crypto.randomBytes(8).toString('hex');
  const fileName = `screenshots/${userId}_${timestamp}_${random}.jpg`;
  const fileUpload = bucket.file(fileName);
  const downloadToken = crypto.randomBytes(16).toString('hex');
  
  await fileUpload.save(file.buffer, {
    metadata: {
      contentType: file.mimetype,
      metadata: { firebaseStorageDownloadTokens: downloadToken }
    }
  });
  
  await fileUpload.makePublic();
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(fileName)}?alt=media&token=${downloadToken}`;
};

module.exports = { uploadScreenshots, uploadToFirebase };
