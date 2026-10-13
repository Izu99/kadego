const router = require('express').Router();
const Notification = require('../models/Notification');
const { requireAuth } = require('../auth');

router.use(requireAuth);

// GET /api/notifications -> { items, unread }
router.get('/', async (req, res) => {
  const [items, unread] = await Promise.all([
    Notification.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(50),
    Notification.countDocuments({ user: req.user._id, read: false }),
  ]);
  res.json({ items, unread });
});

// PUT /api/notifications/read-all
router.put('/read-all', async (req, res) => {
  await Notification.updateMany({ user: req.user._id, read: false }, { read: true });
  res.json({ message: 'All read' });
});

module.exports = router;
