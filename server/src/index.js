require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const seed = require('./seed');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ ok: true }));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/items', require('./routes/items'));
app.use('/api/cart', require('./routes/cart'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/notifications', require('./routes/notifications'));

// Bad ObjectIds and validation errors -> 400 instead of a crash
app.use((err, req, res, next) => {
  if (err.name === 'CastError' || err.name === 'ValidationError') {
    return res.status(400).json({ message: err.message });
  }
  console.error(err);
  res.status(500).json({ message: 'Server error' });
});

async function start() {
  let uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!uri) {
    // No MONGO_URI set: run a throwaway local MongoDB so the app works out of the box.
    const { MongoMemoryServer } = require('mongodb-memory-server');
    const mem = await MongoMemoryServer.create();
    uri = mem.getUri('kadego');
    console.log('MONGO_URI not set - using in-memory MongoDB (data resets on restart)');
  }
  await mongoose.connect(uri);
  await seed();
  const port = process.env.PORT || 5000;
  app.listen(port, '0.0.0.0', () => console.log(`KadeGo API on http://localhost:${port}`));
}

start().catch((e) => {
  console.error(e);
  process.exit(1);
});
