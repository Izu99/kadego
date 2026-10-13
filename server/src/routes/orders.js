const router = require('express').Router();
const Order = require('../models/Order');
const CartItem = require('../models/CartItem');
const Item = require('../models/Item');
const { requireAuth, requireRole } = require('../auth');
const { notifyUser, notifyShop } = require('../notify');

router.use(requireAuth);

const NEXT = { sent: 'confirmed', confirmed: 'packing', packing: 'ready', ready: 'collected' };

// What the customer is told when the shop moves their order on
const CUSTOMER_MSG = {
  confirmed: (o) => ['Shop confirmed your order', `${o.shop} accepted order #${o.number}.`, 'check'],
  packing: (o) => ['Your order is being packed', `${o.shop} is packing order #${o.number} now.`, 'bags'],
  ready: (o) => ['Your order is ready for pickup', `Order #${o.number} at ${o.shop}. Show code ${o.code} at the counter.`, 'check'],
  collected: (o) => ['Order collected', `Thanks for picking up order #${o.number}!`, 'bags'],
  cancelled: (o) => ['Order cancelled', `Order #${o.number} at ${o.shop} was cancelled.`, 'other'],
};

const restock = (order) =>
  Promise.all(order.lines.map((l) => Item.updateOne({ _id: l.item }, { $inc: { stock: l.quantity } })));

// POST /api/orders { pickupDay, pickupSlot, payment } — turns the customer's cart into an order
router.post('/', requireRole('customer'), async (req, res) => {
  const { pickupDay = 'today', pickupSlot, payment = 'Cash at pickup' } = req.body;
  if (!pickupSlot) return res.status(400).json({ message: 'Choose a pickup time' });

  const cart = (await CartItem.find({ user: req.user._id }).populate('item')).filter((l) => l.item);
  if (cart.length === 0) return res.status(400).json({ message: 'Your pre-order is empty' });

  // Reserve stock line by line; undo everything if one item doesn't have enough
  const taken = [];
  for (const l of cart) {
    const ok = await Item.findOneAndUpdate(
      { _id: l.item._id, stock: { $gte: l.quantity } },
      { $inc: { stock: -l.quantity } }
    );
    if (!ok) {
      await Promise.all(taken.map((t) => Item.updateOne({ _id: t.id }, { $inc: { stock: t.qty } })));
      return res.status(400).json({ message: `Only ${l.item.stock} ${l.item.name} left – update your pre-order` });
    }
    taken.push({ id: l.item._id, qty: l.quantity });
  }

  const lines = cart.map((l) => ({
    item: l.item._id,
    name: l.item.name,
    brand: l.brand,
    image: l.item.image,
    price: l.item.price,
    quantity: l.quantity,
  }));
  const order = await Order.create({
    number: `KG-${2040 + (await Order.countDocuments()) + 1}`,
    code: String(Math.floor(1000 + Math.random() * 9000)),
    user: req.user._id,
    customerName: req.user.name,
    shop: cart[0].item.shop,
    lines,
    total: lines.reduce((s, l) => s + l.price * l.quantity, 0),
    pickupDay,
    pickupSlot,
    payment,
    history: [{ status: 'sent' }],
  });
  await CartItem.deleteMany({ user: req.user._id });

  await notifyShop(order.shop, {
    type: 'new_order',
    title: `New order #${order.number}`,
    body: `${order.customerName} • ${lines.length} item${lines.length === 1 ? '' : 's'} • Rs. ${order.total} • pickup ${pickupSlot} ${pickupDay}`,
    image: 'bags',
    order: order._id,
  });
  res.status(201).json(order);
});

// GET /api/orders — customers see their own, shop owners see their shop's
router.get('/', async (req, res) => {
  const filter = req.user.role === 'store' ? { shop: req.user.shop } : { user: req.user._id };
  res.json(await Order.find(filter).sort({ createdAt: -1 }).limit(100));
});

router.get('/:id', async (req, res) => {
  const order = await Order.findById(req.params.id);
  const mine = order && (req.user.role === 'store' ? order.shop === req.user.shop : order.user.equals(req.user._id));
  if (!mine) return res.status(404).json({ message: 'Order not found' });
  res.json(order);
});

// PUT /api/orders/:id/status { status } — shop moves the order to the next step (or cancels it)
router.put('/:id/status', requireRole('store'), async (req, res) => {
  const { status } = req.body;
  const order = await Order.findOne({ _id: req.params.id, shop: req.user.shop });
  if (!order) return res.status(404).json({ message: 'Order not found' });

  const canCancel = ['sent', 'confirmed', 'packing'].includes(order.status);
  if (status === 'cancelled' ? !canCancel : NEXT[order.status] !== status) {
    return res.status(400).json({ message: `Can't change a "${order.status}" order to "${status}"` });
  }

  order.status = status;
  order.history.push({ status });
  await order.save();
  if (status === 'cancelled') await restock(order);

  const [title, body, image] = CUSTOMER_MSG[status](order);
  await notifyUser(order.user, { type: 'order_status', title, body, image, order: order._id });
  res.json(order);
});

module.exports = router;
