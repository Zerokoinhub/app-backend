const User = require("../models/User");
module.exports = async (req, res, next) => {
  const user = await User.findOne();
  if (!user) return res.status(401).json({ message: "Unauthorized" });
  req.user = user;
  next();
};
