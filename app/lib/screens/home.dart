import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'notifications.dart';
import 'shop.dart';

// Shops are hardcoded; only Perera Stores is backed by the API.
const shops = [
  (name: 'Perera Stores', meta: '0.4 km  •  Open until 10 pm', status: 'quiet'),
  (name: 'Silva Grocery – Negombo', meta: '0.9 km  •  Open until 9 pm', status: 'busy'),
  (name: 'Lanka Mini Mart', meta: '1.3 km  •  Open until 9:30 pm', status: 'quiet'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openShop(BuildContext context, [String category = 'All']) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(initialCategory: category)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pickup near', style: t(12, c: C.muted)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_outlined, color: C.orange, size: 18),
                  const SizedBox(width: 4),
                  Flexible(child: Text('Negombo', overflow: TextOverflow.ellipsis, style: t(17, w: FontWeight.w500))),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                ]),
              ]),
            ),
            BellButton(
                onTap: () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openShop(context),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.search_rounded, color: C.muted, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Search rice, milk powder, shops...',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: t(14, c: C.muted)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          _banner(context),
          const SizedBox(height: 24),
          SectionHead('Categories', onSeeAll: () => _openShop(context)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final c in const [
              ('Rice', 'rice', 'Rice & Grains'),
              ('Dairy', 'milk', 'Dairy'),
              ('Bakery', 'bread', 'Bakery'),
              ('Eggs', 'eggs', 'Eggs'),
            ])
              GestureDetector(
                onTap: () => _openShop(context, c.$3),
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: C.orangeSoft, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: img(c.$2, 36),
                  ),
                  const SizedBox(height: 8),
                  Text(c.$1, style: t(13)),
                ]),
              ),
          ]),
          const SizedBox(height: 24),
          SectionHead('Shops near you', onSeeAll: () {}),
          const SizedBox(height: 12),
          for (final s in shops) _shopCard(context, s.name, s.meta, s.status),
        ]),
      ),
    );
  }

  Widget _banner(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
        decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Skip the 6pm rush', style: t(20, w: FontWeight.w700, c: Colors.white)),
              const SizedBox(height: 6),
              Text('Pre-order now and pick up when it\'s quiet.', style: t(13, c: Colors.white)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _openShop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text('Pre-order now', style: t(13, w: FontWeight.w600, c: C.orange)),
                ),
              ),
            ]),
          ),
          img('cart', 60),
        ]),
      );

  Widget _shopCard(BuildContext context, String name, String meta, String status) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => name == 'Perera Stores' ? _openShop(context) : toast(context, '$name – coming soon'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.line),
              ),
              child: Row(children: [
                ProductThumb('store', size: 64, bg: C.orangeSoft),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(15, w: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(meta, style: t(12, c: C.muted)),
                    const SizedBox(height: 6),
                    StockBadge(status),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.muted),
              ]),
            ),
          ),
        ),
      );
}
