const mongoose = require('mongoose');

// In-app notification for one user (customer or shop owner).
const notificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, enum: ['new_order', 'order_status', 'back_in_stock'], required: true },
    title: { type: String, required: true },
    body: { type: String, default: '' },
    image: { type: String, default: 'bags' }, // app image key
    order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
    item: { type: mongoose.Schema.Types.ObjectId, ref: 'Item' },
    read: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
