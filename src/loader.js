// src/models/loader.js
const path = require('path');
const fs = require('fs');

function findUserModel() {
  // Possible locations for the user model
  const possiblePaths = [
    path.join(__dirname, '../../models/user.js'),
    path.join(__dirname, '../../models/user.model.js'),
    path.join(__dirname, '../models/user.js'),
    path.join(__dirname, '../models/user.model.js'),
    path.join(__dirname, './models/user.js'),
    path.join(__dirname, './models/user.model.js'),
  ];
  
  for (const modelPath of possiblePaths) {
    try {
      if (fs.existsSync(modelPath)) {
        console.log(`✅ Found User model at: ${modelPath}`);
        return require(modelPath);
      }
    } catch (err) {
      // Continue searching
    }
  }
  
  throw new Error('User model not found in any location');
}

module.exports = { findUserModel };
