const Notification = require('./models/Notification');
const User = require('./models/User');

// Notify one user.
const notifyUser = (user, data) => Notification.create({ user, ...data });

// Notify every shop-owner account of a shop.
async function notifyShop(shop, data) {
  const owners = await User.find({ role: 'store', shop }).select('_id');
  await Notification.insertMany(owners.map((o) => ({ user: o._id, ...data })));
}

module.exports = { notifyUser, notifyShop };
