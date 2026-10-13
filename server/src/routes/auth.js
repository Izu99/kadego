const router = require('express').Router();
const User = require('../models/User');
const { sign, requireAuth } = require('../auth');

// POST /api/auth/register { name, phone, password } — customers only; store accounts are created by seed/admin.
router.post('/register', async (req, res) => {
  const { name, phone, password } = req.body;
  if (!name || !phone || !password) return res.status(400).json({ message: 'Name, phone and password are required' });
  if (String(password).length < 4) return res.status(400).json({ message: 'Password must be at least 4 characters' });
  if (await User.exists({ phone })) return res.status(400).json({ message: 'This phone number is already registered' });
  const user = await User.create({ name, phone, password, role: 'customer' });
  res.status(201).json({ token: sign(user), user });
});

// POST /api/auth/login { phone, password }
router.post('/login', async (req, res) => {
  const { phone, password } = req.body;
  const user = await User.findOne({ phone: String(phone || '').trim() });
  if (!user || !(await user.checkPassword(String(password || '')))) {
    return res.status(401).json({ message: 'Wrong phone number or password' });
  }
  res.json({ token: sign(user), user });
});

router.get('/me', requireAuth, (req, res) => res.json(req.user));

module.exports = router;
