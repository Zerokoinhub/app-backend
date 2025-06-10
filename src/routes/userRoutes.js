const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);

module.exports = router;