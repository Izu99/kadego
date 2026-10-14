require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const seed = require('./seed');

// Connects once and reuses the connection. Serverless (Vercel) keeps the module
// alive between requests, so later requests skip straight to the cached promise.
let ready;
function connectDb() {
  if (!ready) {
    ready = (async () => {
      let uri = process.env.MONGO_URI || process.env.MONGODB_URI;
      if (!uri) {
        // No MONGO_URI set: run a throwaway local MongoDB so the app works out of the box.
        let MongoMemoryServer;
        try {
          ({ MongoMemoryServer } = require('mongodb-memory-server')); // dev dependency only
        } catch {
          throw new Error('MONGO_URI is not set. Add your MongoDB Atlas link as the MONGO_URI environment variable.');
        }
        const mem = await MongoMemoryServer.create();
        uri = mem.getUri('kadego');
        console.log('MONGO_URI not set - using in-memory MongoDB (data resets on restart)');
      }
      await mongoose.connect(uri);
      await seed();
    })().catch((e) => {
      ready = null; // let the next request retry instead of failing forever
      throw e;
    });
  }
  return ready;
}

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ ok: true }));
app.use(async (req, res, next) => {
  try {
    await connectDb();
    next();
  } catch (e) {
    next(e);
  }
});
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

module.exports = { app, connectDb };
