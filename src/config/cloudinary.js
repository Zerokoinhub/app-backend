const cloudinary = require('cloudinary').v2;

// ✅ Add detailed logging
console.log('🔧 Initializing Cloudinary...');
console.log('🔧 Cloud Name:', process.env.CLOUDINARY_CLOUD_NAME || 'NOT SET');
console.log('🔧 API Key:', process.env.CLOUDINARY_API_KEY ? 'SET' : 'NOT SET');
console.log('🔧 API Secret:', process.env.CLOUDINARY_API_SECRET ? 'SET' : 'NOT SET');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true
});

module.exports = cloudinary;
