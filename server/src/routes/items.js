const router = require('express').Router();
const Item = require('../models/Item');
const CartItem = require('../models/CartItem');
const StockAlert = require('../models/StockAlert');
const { requireAuth, requireRole } = require('../auth');
const { notifyUser } = require('../notify');

const storeOnly = [requireAuth, requireRole('store')];

const FIELDS = ['name', 'shop', 'category', 'description', 'brands', 'price', 'stock', 'image'];
const pick = (body) => Object.fromEntries(FIELDS.filter((k) => body[k] !== undefined).map((k) => [k, body[k]]));

// Anyone can browse items; only store accounts can add / edit / delete.
// GET /api/items?category=Dairy
router.get('/', async (req, res) => {
  const filter = {};
  if (req.query.category && req.query.category !== 'All') filter.category = req.query.category;
  res.json(await Item.find(filter).sort({ createdAt: 1 }));
});

router.get('/:id', async (req, res) => {
  const item = await Item.findById(req.params.id);
  if (!item) return res.status(404).json({ message: 'Item not found' });
  res.json(item);
});

router.post('/', storeOnly, async (req, res) => {
  const item = await Item.create({ ...pick(req.body), shop: req.user.shop || 'Perera Stores' });
  res.status(201).json(item);
});

router.put('/:id', storeOnly, async (req, res) => {
  const before = await Item.findById(req.params.id);
  if (!before) return res.status(404).json({ message: 'Item not found' });
  const item = await Item.findByIdAndUpdate(req.params.id, pick(req.body), { returnDocument: 'after', runValidators: true });

  // Restocked a sold-out item -> tell everyone who tapped "Notify me when back"
  if (before.stock <= 0 && item.stock > 0) {
    const alerts = await StockAlert.find({ item: item._id });
    await Promise.all(
      alerts.map((a) =>
        notifyUser(a.user, {
          type: 'back_in_stock',
          title: `${item.name} is back in stock`,
          body: `${item.shop} restocked it. Pre-order before it sells out again.`,
          image: item.image,
          item: item._id,
        })
      )
    );
    await StockAlert.deleteMany({ item: item._id });
  }
  res.json(item);
});

// POST /api/items/:id/notify-me — customer asks to be told when a sold-out item is back
router.post('/:id/notify-me', requireAuth, requireRole('customer'), async (req, res) => {
  const item = await Item.findById(req.params.id);
  if (!item) return res.status(404).json({ message: 'Item not found' });
  await StockAlert.updateOne({ user: req.user._id, item: item._id }, {}, { upsert: true });
  res.json({ message: `We'll notify you when ${item.name} is back` });
});

router.delete('/:id', storeOnly, async (req, res) => {
  const item = await Item.findByIdAndDelete(req.params.id);
  if (!item) return res.status(404).json({ message: 'Item not found' });
  // Remove it from any cart too, so the cart never points at a deleted item
  await CartItem.deleteMany({ item: item._id });
  await StockAlert.deleteMany({ item: item._id });
  res.json({ message: 'Deleted' });
});

module.exports = router;
