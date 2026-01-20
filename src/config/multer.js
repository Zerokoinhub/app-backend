const multer = require('multer');

// ✅ SIMPLE MEMORY STORAGE - Remove CloudinaryStorage dependency
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    console.log('📁 File filter - File:', file.originalname, 'Type:', file.mimetype);

    // Check MIME type
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
      return;
    }

    // Check file extension as fallback
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));

    if (allowedExtensions.includes(fileExtension)) {
      console.log('✅ File accepted based on extension:', fileExtension);
      cb(null, true);
    } else {
      console.log('❌ File rejected - Extension:', fileExtension, 'MIME:', file.mimetype);
      cb(new Error('Only image files (JPG, JPEG, PNG, GIF, WebP) are allowed!'), false);
    }
  }
});

module.exports = upload;
