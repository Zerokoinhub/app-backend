const User = require('../models/User');
const crypto = require('crypto');

const generateInviteCode = () => {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
};

exports.registerUser = async (req, res) => {
  try {
    let inviteCode = generateInviteCode();
    while (await User.findOne({ inviteCode })) {
      inviteCode = generateInviteCode();
    }
    const user = new User({ inviteCode });
    await user.save();
    res.status(201).json({ inviteCode });
  } catch (error) {
    res.status(500).json({ message: 'Error registering user' });
  }
};

exports.getInviteDetails = async (req, res) => {
  try {
    const { inviteCode } = req.params;
    const user = await User.findOne({ inviteCode });
    if (!user) return res.status(404).json({ message: 'Invite not found' });
    res.json({ inviteCode, recentAmount: user.recentAmount });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching invite details' });
  }
};

exports.processReferral = async (req, res) => {
  try {
    const { inviteCode, referredBy } = req.body;
    console.log('Processing referral:', { inviteCode, referredBy });

    const referrer = await User.findOne({ inviteCode: referredBy });
    if (!referrer) return res.status(400).json({ message: 'Invalid referrer invite code' });

    let newInviteCode = generateInviteCode();
    while (await User.findOne({ inviteCode: newInviteCode })) {
      newInviteCode = generateInviteCode();
    }

    const newUser = new User({ inviteCode: newInviteCode, referredBy });
    await newUser.save();

    referrer.recentAmount += 50;
    await referrer.save();

    res.status(200).json({ message: 'Referral processed', recentAmount: referrer.recentAmount });
  } catch (error) {
    console.error('Referral error:', error.message);
    res.status(500).json({ message: 'Error processing referral', error: error.message });
  }
};