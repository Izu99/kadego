// Local / Render entry: connect first, then listen. Vercel uses api/index.js instead.
const { app, connectDb } = require('./app');

connectDb()
  .then(() => {
    const port = process.env.PORT || 5000;
    app.listen(port, '0.0.0.0', () => console.log(`KadeGo API on http://localhost:${port}`));
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
