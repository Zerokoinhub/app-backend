const Withdrawal = require('../models/withdraw');
const User = require('../models/User');

exports.withdrawCoins = async (req, res) => {
  const { userId, amount, walletAddress } = req.body;

  if (!userId || !amount || !walletAddress) {
    return res.status(400).json({ message: 'User ID, amount, and wallet address required' });
  }

  const user = await User.findById(userId);
  if (!user || user.balance < 4000) {
    return res.status(400).json({ message: 'You must have at least 4000 balance to withdraw.' });
  }
  if (user.balance < amount) {
    return res.status(400).json({ message: 'Insufficient balance' });
  }

  user.balance -= amount;
  await user.save();

  const withdrawal = await Withdrawal.create({ user: userId, amount, walletAddress, status: 'pending' });
  res.status(201).json({ message: 'Withdrawal requested', withdrawal });
};

exports.getWithdrawalHistory = async (req, res) => {
  const isAdmin = req.user.role === 'admin';
  const filter = isAdmin ? {} : { user: req.user._id };
  const history = await Withdrawal.find(filter).populate('user', 'email');
  res.json(history);
};