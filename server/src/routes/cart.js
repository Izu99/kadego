const router = require('express').Router();
const CartItem = require('../models/CartItem');
const Item = require('../models/Item');
const { requireAuth, requireRole } = require('../auth');

// Every cart route works on the logged-in customer's own cart only.
router.use(requireAuth, requireRole('customer'));

const list = (user) => CartItem.find({ user }).populate('item').sort({ createdAt: 1 });

// GET /api/cart -> lines plus totals
router.get('/', async (req, res) => {
  const lines = (await list(req.user._id)).filter((l) => l.item);
  const subtotal = lines.reduce((sum, l) => sum + l.item.price * l.quantity, 0);
  res.json({ items: lines, subtotal, pickupFee: 0, total: subtotal });
});

// POST /api/cart { itemId, brand, quantity } — adding the same item+brand again increases quantity
router.post('/', async (req, res) => {
  const { itemId, brand = '', quantity = 1 } = req.body;
  const item = await Item.findById(itemId);
  if (!item) return res.status(404).json({ message: 'Item not found' });
  if (item.stock <= 0) return res.status(400).json({ message: 'Item is sold out' });

  const existing = await CartItem.findOne({ user: req.user._id, item: itemId, brand });
  if (existing) {
    existing.quantity += Number(quantity);
    await existing.save();
    return res.json(await existing.populate('item'));
  }
  const line = await CartItem.create({ user: req.user._id, item: itemId, brand, quantity });
  res.status(201).json(await line.populate('item'));
});

// PUT /api/cart/:id { quantity }
router.put('/:id', async (req, res) => {
  const quantity = Number(req.body.quantity);
  if (!(quantity >= 1)) return res.status(400).json({ message: 'Quantity must be at least 1' });
  const line = await CartItem.findOneAndUpdate({ _id: req.params.id, user: req.user._id }, { quantity }, { returnDocument: 'after' }).populate('item');
  if (!line) return res.status(404).json({ message: 'Cart item not found' });
  res.json(line);
});

// DELETE /api/cart/:id
router.delete('/:id', async (req, res) => {
  const line = await CartItem.findOneAndDelete({ _id: req.params.id, user: req.user._id });
  if (!line) return res.status(404).json({ message: 'Cart item not found' });
  res.json({ message: 'Removed' });
});

// DELETE /api/cart -> clear (after placing the pre-order)
router.delete('/', async (req, res) => {
  await CartItem.deleteMany({ user: req.user._id });
  res.json({ message: 'Cart cleared' });
});

module.exports = router;
