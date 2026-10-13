const mongoose = require('mongoose');

// A product a shop sells. Managed from the store side (Store > Manage items).
const itemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    shop: { type: String, default: 'Perera Stores' },
    category: { type: String, enum: ['Rice & Grains', 'Dairy', 'Bakery', 'Eggs', 'Other'], default: 'Other' },
    description: { type: String, default: '' }, // e.g. "Araliya, Nipuna • 2 brands"
    brands: { type: [String], default: [] },
    price: { type: Number, required: true, min: 0 },
    stock: { type: Number, default: 0, min: 0 }, // units left; 0 = sold out
    image: { type: String, default: 'rice' }, // one of the bundled image keys
  },
  { timestamps: true }
);

// Stock badge shown in the app: In stock / Low stock / Sold out
itemSchema.virtual('stockStatus').get(function () {
  if (this.stock <= 0) return 'sold_out';
  if (this.stock <= 3) return 'low_stock';
  return 'in_stock';
});

itemSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Item', itemSchema);
