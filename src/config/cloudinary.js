const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

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

// ✅ CREATE STORAGE FOR SCREENSHOTS
const screenshotStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'user_screenshots',
    format: async (req, file) => {
      const ext = file.originalname.split('.').pop().toLowerCase();
      return ext === 'png' ? 'png' : 'jpg';
    },
    public_id: (req, file) => {
      const timestamp = Date.now();
      const random = Math.random().toString(36).substring(2, 10);
      return `screenshot_${timestamp}_${random}`;
    }
  }
});

// ✅ CREATE MULTER UPLOAD MIDDLEWARE
const uploadScreenshots = multer({ 
  storage: screenshotStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, JPG, PNG images are allowed'), false);
    }
  }
});

module.exports = { cloudinary, uploadScreenshots };
