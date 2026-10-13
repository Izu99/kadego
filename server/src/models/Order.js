const mongoose = require('mongoose');

const STATUSES = ['sent', 'confirmed', 'packing', 'ready', 'collected', 'cancelled'];

// A placed pre-order. Lines are copied from the cart so later price changes don't alter it.
const orderSchema = new mongoose.Schema(
  {
    number: { type: String, required: true, unique: true }, // e.g. KG-2041
    code: { type: String, required: true }, // 4-digit pickup code shown at the counter
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    customerName: String,
    shop: { type: String, default: 'Perera Stores', index: true },
    lines: [
      {
        item: { type: mongoose.Schema.Types.ObjectId, ref: 'Item' },
        name: String,
        brand: String,
        image: String,
        price: Number,
        quantity: Number,
      },
    ],
    total: { type: Number, required: true },
    pickupDay: { type: String, enum: ['today', 'tomorrow'], default: 'today' },
    pickupSlot: { type: String, required: true }, // "4:30 pm"
    payment: { type: String, default: 'Cash at pickup' },
    status: { type: String, enum: STATUSES, default: 'sent' },
    // when each status was reached, for the order-status timeline
    history: [{ status: String, at: { type: Date, default: Date.now } }],
  },
  { timestamps: true }
);

orderSchema.statics.STATUSES = STATUSES;

module.exports = mongoose.model('Order', orderSchema);
