// Add MongoDB connection at the top
const mongoose = require('mongoose');
const User = require('../models/User'); // You need a User model

// ============ UPDATE PROFILE ROUTE ============
router.put('/profile', verifyFirebaseToken, async (req, res) => {
  console.log('✅ PUT /profile called with data:', req.body);
  
  if (!req.body || Object.keys(req.body).length === 0) {
    return res.status(400).json({
      success: false,
      message: 'No data provided for update'
    });
  }
  
  try {
    const userId = req.user.uid;
    const { displayName, photoURL, email } = req.body;
    
    console.log(`🔄 Updating user ${userId} with:`, {
      displayName,
      photoURL,
      email
    });
    
    // Find user by Firebase UID and update
    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: userId }, // Find by Firebase UID
      { 
        $set: {
          displayName: displayName,
          photoURL: photoURL,
          email: email || req.user.email,
          updatedAt: new Date()
        }
      },
      { 
        new: true, // Return updated document
        upsert: false // Don't create if doesn't exist
      }
    );
    
    if (!updatedUser) {
      // User doesn't exist in MongoDB yet, create them
      const newUser = await User.create({
        firebaseUid: userId,
        displayName: displayName,
        photoURL: photoURL,
        email: email || req.user.email,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      return res.json({
        success: true,
        message: 'User created successfully',
        user: newUser,
        timestamp: new Date().toISOString()
      });
    }
    
    console.log('✅ MongoDB update successful:', updatedUser);
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      updatedFields: req.body,
      user: updatedUser,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ MongoDB update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: error.message
    });
  }
});
