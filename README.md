# KadeGo

Pre-order groceries from your local kade and pick them up when the shop is quiet.

- `server/` – Node.js + Express + MongoDB API
- `app/` – Flutter mobile app (built from the Figma high-fidelity design)

## What is real and what is hardcoded

| Part | Status |
|---|---|
| Login / sign-up (customer and shop-owner roles) | **Real** – `/api/auth` |
| Store side – items (add / view / edit / delete) | **Real** – `/api/items` |
| Customer side – pre-order cart (add / view / change quantity / remove) | **Real** – `/api/cart` |
| Orders – place, track, shop moves status (confirm → packing → ready → collected / cancel) | **Real** – `/api/orders` |
| Notifications – new order (shop), status updates and back-in-stock (customer) | **Real** – `/api/notifications` |
| Shop list, busy-times chart, pickup slots, payment, Sinhala/Tamil | Hardcoded for the demo |

Screens refresh themselves every few seconds, so changes show up without a manual refresh.

### Demo accounts

| Role | Phone | Password |
|---|---|---|
| Customer | 0771234567 | 1234 |
| Shop owner | 0770000000 | 1234 |

## Run the backend

```bash
cd server
npm install
npm start
```

The API runs on `http://localhost:5000`. If `MONGO_URI` is not set, the server starts a
built-in in-memory MongoDB and adds 4 starter items (data resets on restart). To keep data,
copy `.env.example` to `.env` and set `MONGO_URI` (local MongoDB or MongoDB Atlas).

### API

| Method | Path | Does |
|---|---|---|
| GET | `/api/items?category=Dairy` | list items |
| GET | `/api/items/:id` | one item |
| POST | `/api/items` | add item `{name, price, stock, category, description, brands[], image}` |
| PUT | `/api/items/:id` | edit item |
| DELETE | `/api/items/:id` | delete item (also removes it from the cart) |
| GET | `/api/cart` | cart lines + subtotal/total |
| POST | `/api/cart` | add `{itemId, brand, quantity}` (same item again → quantity increases) |
| PUT | `/api/cart/:id` | change `{quantity}` |
| DELETE | `/api/cart/:id` | remove a line |
| DELETE | `/api/cart` | clear cart |
| POST | `/api/auth/login`, `/api/auth/register` | log in / customer sign-up |
| POST | `/api/orders` | place order from cart `{pickupDay, pickupSlot, payment}` |
| GET | `/api/orders` | my orders (customer) / shop orders (shop owner) |
| PUT | `/api/orders/:id/status` | shop moves order to next status `{status}` |
| GET | `/api/notifications` | notifications + unread count |
| PUT | `/api/notifications/read-all` | mark all read |
| POST | `/api/items/:id/notify-me` | customer: alert me when back in stock |

Item add/edit/delete need a shop-owner login; cart and order placing need a customer login
(`Authorization: Bearer <token>`).

## Run the app

```bash
cd app
flutter pub get
flutter run                     # Android emulator – talks to the PC at 10.0.2.2:5000
flutter run -d chrome           # browser – talks to localhost:5000
```

On a **real phone**, connect it to the same Wi-Fi as the PC and pass the PC's IP:

```bash
flutter run --dart-define=API_URL=http://192.168.1.10:5000
flutter build apk --release --dart-define=API_URL=http://192.168.1.10:5000
```

The APK is created at `app/build/app/outputs/flutter-apk/app-release.apk`.

## Credits

Product images are from Microsoft's [Fluent Emoji](https://github.com/microsoft/fluentui-emoji) (MIT licence).
