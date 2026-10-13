import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';
import 'item_details.dart';

const categories = ['All', 'Rice & Grains', 'Dairy', 'Bakery', 'Eggs'];

class ShopScreen extends StatefulWidget {
  final bool showBack;
  final String initialCategory;
  const ShopScreen({super.key, this.showBack = true, this.initialCategory = 'All'});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with LiveReload {
  late String _category = widget.initialCategory;
  late Future<List<Item>> _items = Api.items(category: _category);
  bool _saved = false;

  void _reload() => setState(() { _items = Api.items(category: _category); });

  @override
  Future<void> liveReload() async {
    final items = await Api.items(category: _category);
    if (mounted) setState(() { _items = Future.value(items); });
  }

  Future<void> _open(Item item) async {
    await Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (_) => ItemDetailsScreen(itemId: item.id)));
    _reload();
  }

  Future<void> _quickAdd(Item item) async {
    try {
      await Api.addToCart(item.id, brand: item.brands.isEmpty ? '' : item.brands.first);
      if (mounted) {
        toast(context, '${item.name} added to pre-order',
            action: SnackBarAction(label: 'View', textColor: C.orange, onPressed: _openCart));
      }
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _openCart() async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const CartScreen()));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), children: [
            Row(children: [
              if (widget.showBack) CircleIcon(Icons.chevron_left_rounded, onTap: () => Navigator.maybePop(context)),
              const Spacer(),
              CircleIcon(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  onTap: () => setState(() { _saved = !_saved; })),
            ]),
            const SizedBox(height: 18),
            Text('Perera Stores', style: t(24, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Main Street, Negombo  •  0.4 km  •  Open until 10 pm', style: t(13, c: C.muted)),
            const SizedBox(height: 8),
            const Wrap(spacing: 8, runSpacing: 6, children: [
              StockBadge('quiet'),
              Pill('Ready in ~15 min', fg: C.muted, bg: C.surface),
            ]),
            const SizedBox(height: 16),
            const BusyChart(),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChipX(categories[i], selected: categories[i] == _category, onTap: () {
                  _category = categories[i];
                  _reload();
                }),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Item>>(
              future: _items,
              builder: (context, snap) {
                if (snap.hasError) return ErrorRetry(snap.error!, _reload);
                if (!snap.hasData) {
                  return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('No items in this category yet.', textAlign: TextAlign.center, style: t(14, c: C.muted)),
                  );
                }
                return Column(children: [for (final i in items) _row(i)]);
              },
            ),
          ]),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: Api.cartCount,
        builder: (_, n, __) => n == 0
            ? const SizedBox.shrink()
            : BottomCta(child: PrimaryButton('View pre-order  •  $n item${n == 1 ? '' : 's'}', onTap: _openCart)),
      ),
    );
  }

  Widget _row(Item i) => InkWell(
        onTap: () => _open(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ProductThumb(i.image, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.name, style: t(15, w: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(i.description, style: t(12, c: C.muted)),
                const SizedBox(height: 6),
                StockBadge(i.stockStatus, dot: i.stockStatus != 'sold_out' && i.brands.isNotEmpty),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rs(i.price), style: t(15, w: FontWeight.w500)),
              const SizedBox(height: 10),
              i.soldOut
                  ? Material(
                      color: C.orangeSoft,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          try {
                            await Api.notifyMe(i.id);
                            if (mounted) toast(context, 'We\'ll notify you when ${i.name} is back');
                          } catch (e) {
                            if (mounted) toast(context, '$e');
                          }
                        },
                        child: const SizedBox(
                            width: 34, height: 34, child: Icon(Icons.notifications_none_rounded, color: C.orange, size: 20)),
                      ),
                    )
                  : RoundAdd(onTap: () => _quickAdd(i)),
            ]),
          ]),
        ),
      );
}

/// "Busy times today" bar chart — hardcoded data.
class BusyChart extends StatelessWidget {
  const BusyChart({super.key});
  static const _bars = [('8a', .25), ('10a', .45), ('12p', .6), ('2p', .35), ('4p', .3), ('5p', .75), ('6p', .95), ('8p', .4)];
  static const _now = 4;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text('Busy times today', style: t(15, w: FontWeight.w500))),
            Text('Usually busy 5–7 pm', style: t(12, c: C.muted)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < _bars.length; i++)
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (i == _now) Text('Now', style: t(10, w: FontWeight.w500, c: C.orange)),
                    if (i == _now) const SizedBox(height: 3),
                    Container(
                      width: 24,
                      height: 60 * _bars[i].$2,
                      decoration: BoxDecoration(
                        color: i == _now ? C.orange : const Color(0xFFFFC9A3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_bars[i].$1, style: t(10, c: C.muted)),
                  ]),
                ),
            ]),
          ),
        ]),
      );
}
