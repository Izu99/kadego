const mongoose = require('mongoose');

// "Notify me when back" — a customer waiting for a sold-out item.
const stockAlertSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    item: { type: mongoose.Schema.Types.ObjectId, ref: 'Item', required: true, index: true },
  },
  { timestamps: true }
);

stockAlertSchema.index({ user: 1, item: 1 }, { unique: true });

module.exports = mongoose.model('StockAlert', stockAlertSchema);
