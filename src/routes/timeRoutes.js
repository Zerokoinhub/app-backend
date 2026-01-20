const express = require('express');
const router = express.Router();
const timeController = require('../controllers/timeController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// ✅ PUBLIC: Get server time for initial sync (NO AUTH)
router.get('/server-time-public', timeController.getServerTimePublic);

// ✅ AUTHENTICATED: Get server time with user context
router.get('/server-time', verifyFirebaseToken, timeController.getServerTime);

// Validate session timing against server time
router.post('/validate-session', verifyFirebaseToken, timeController.validateSessionTiming);

// Get time validation status
router.get('/validation-status', verifyFirebaseToken, timeController.getTimeValidationStatus);

// Force session unlock based on server time
router.post('/force-unlock', verifyFirebaseToken, timeController.forceSessionUnlock);

// ✅ PUBLIC: Simple health check
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    service: 'time-service',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

module.exports = router;
