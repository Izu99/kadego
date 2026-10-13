const jwt = require('jsonwebtoken');
const User = require('./models/User');

const SECRET = process.env.JWT_SECRET || 'kadego-dev-secret-change-me';

const sign = (user) => jwt.sign({ id: user._id, role: user.role }, SECRET, { expiresIn: '30d' });

// Requires a valid "Authorization: Bearer <token>" header; sets req.user.
async function requireAuth(req, res, next) {
  const token = (req.headers.authorization || '').replace(/^Bearer /, '');
  try {
    const { id } = jwt.verify(token, SECRET);
    req.user = await User.findById(id);
    if (!req.user) throw new Error();
    next();
  } catch {
    res.status(401).json({ message: 'Please log in again' });
  }
}

const requireRole = (role) => (req, res, next) =>
  req.user.role === role ? next() : res.status(403).json({ message: `Only ${role} accounts can do this` });

module.exports = { sign, requireAuth, requireRole };
