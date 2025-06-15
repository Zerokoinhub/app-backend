const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { getUserSessions, unlockNextSession } = require('../controllers/userController');
const auth = require('../middleware/auth');

router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);
router.get('/sessions', auth, getUserSessions);
router.post('/unlock', auth, unlockNextSession);
router.post('/sync', auth, userController.syncFirebaseUser);

module.exports = router;