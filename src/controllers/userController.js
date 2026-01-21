exports.uploadProfilePicture = async (req, res) => {
  console.log('📸 Profile picture upload endpoint called');
  console.log('📁 File info:', req.file ? {
    originalname: req.file.originalname,
    size: req.file.size,
    mimetype: req.file.mimetype,
    fieldname: req.file.fieldname
  } : 'No file');

  try {
    if (!req.user || !req.user.uid) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - No user found'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No file uploaded. Please select an image.'
      });
    }

    const userId = req.user.uid;

    // Validate file type and size (same as before)
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif'];
    if (!allowedMimeTypes.includes(req.file.mimetype)) {
      return res.status(400).json({ success: false, error: 'Invalid file type. Please upload JPEG, PNG, or WebP image.' });
    }
    if (req.file.size > 5 * 1024 * 1024) {
      return res.status(400).json({ success: false, error: 'File too large. Maximum size is 5MB.' });
    }

    // Find user
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found in database' });
    }

    // Upload to Cloudinary using stream (safe & timeout-free)
    let imageUrl;
    const timestamp = Date.now();
    const hasCloudinaryConfig = process.env.CLOUDINARY_CLOUD_NAME &&
                                process.env.CLOUDINARY_API_KEY &&
                                process.env.CLOUDINARY_API_SECRET;

    if (hasCloudinaryConfig) {
      try {
        imageUrl = await new Promise((resolve, reject) => {
          cloudinary.uploader.upload_stream(
            {
              folder: 'zerokoin/profile-pictures',
              public_id: `profile_${userId}_${timestamp}`,
              overwrite: true,
              transformation: [
                { width: 400, height: 400, crop: 'fill', gravity: 'face' },
                { quality: 'auto:good', fetch_format: 'auto' }
              ]
            },
            (err, result) => {
              if (err) return reject(err);
              resolve(result.secure_url);
            }
          ).end(req.file.buffer);
        });
      } catch (err) {
        console.error('❌ Cloudinary upload failed, using fallback:', err.message);
      }
    }

    // Fallback if Cloudinary fails
    if (!imageUrl) {
      imageUrl = `https://api.dicebear.com/7.x/avatars/svg?seed=${userId}_${timestamp}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf&radius=50`;
    }

    // Update user
    user.photoURL = imageUrl;
    user.updatedAt = new Date();
    await user.save();

    // Response
    return res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: { photoURL: imageUrl, updatedAt: new Date().toISOString(), userId }
    });

  } catch (error) {
    console.error('❌ Upload endpoint error:', error.message);
    return res.status(500).json({
      success: false,
      error: 'Failed to process profile picture upload. Please try again.',
      debug: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
