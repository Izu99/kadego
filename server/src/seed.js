const Item = require('./models/Item');
const User = require('./models/User');

// Starter items matching the Figma shop screen. Only inserted when the collection is empty.
const ITEMS = [
  { name: 'Samba rice 5 kg', category: 'Rice & Grains', description: 'Araliya, Nipuna • 2 brands', brands: ['Araliya', 'Nipuna'], price: 1450, stock: 20, image: 'rice' },
  { name: 'Milk powder 400 g', category: 'Dairy', description: 'Anchor, Highland, Pelwatte', brands: ['Anchor', 'Highland', 'Pelwatte'], price: 1180, stock: 2, image: 'milk' },
  { name: 'Sandwich bread', category: 'Bakery', description: 'Baked fresh daily', brands: [], price: 160, stock: 0, image: 'bread' },
  { name: 'Eggs (10 pack)', category: 'Eggs', description: 'Farm fresh', brands: [], price: 520, stock: 15, image: 'eggs' },
];

const DEMO_USERS = [
  { name: 'Dilini Fernando', phone: '0771234567', password: '1234', role: 'customer' },
  { name: 'Perera Stores', phone: '0770000000', password: '1234', role: 'store', shop: 'Perera Stores' },
];

module.exports = async function seed() {
  if ((await Item.countDocuments()) === 0) {
    await Item.insertMany(ITEMS);
    console.log('Seeded starter items');
  }
  // Demo accounts (change these passwords for real use)
  for (const u of DEMO_USERS) {
    if (!(await User.exists({ phone: u.phone }))) await User.create(u);
  }
};
