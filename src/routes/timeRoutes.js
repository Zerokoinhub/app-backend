const express = require('express');
const router = express.Router();
const timeController = require('../controllers/timeController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// ✅ PUBLIC: Get server time for initial synchronization (NO AUTH NEEDED)
router.get('/server-time', timeController.getServerTime);

// ✅ PUBLIC: Simple health check (NO AUTH)
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    service: 'time-service',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// ✅ AUTHENTICATED: Get server time with user context
router.get('/server-time-auth', verifyFirebaseToken, timeController.getServerTime);

// Validate session timing against server time
router.post('/validate-session', verifyFirebaseToken, timeController.validateSessionTiming);

// Get time validation status
router.get('/validation-status', verifyFirebaseToken, timeController.getTimeValidationStatus);

// Force session unlock based on server time
router.post('/force-unlock', verifyFirebaseToken, timeController.forceSessionUnlock);

module.exports = router;
