import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailsScreen({super.key, required this.itemId});
  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> with LiveReload {
  late Future<Item> _item = Api.item(widget.itemId);
  String? _brand;
  int _qty = 1;
  bool _busy = false, _saved = false, _notify = false;

  @override
  Future<void> liveReload() async {
    final item = await Api.item(widget.itemId);
    if (!mounted) return;
    setState(() {
      _item = Future.value(item);
      if (_qty > item.stock && item.stock > 0) _qty = item.stock; // stock dropped below chosen qty
      if (!item.brands.contains(_brand)) _brand = item.brands.isEmpty ? '' : item.brands.first;
    });
  }

  Future<void> _add(Item item) async {
    setState(() { _busy = true; });
    try {
      await Api.addToCart(item.id, brand: _brand ?? '', quantity: _qty);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Item>(
      future: _item,
      builder: (context, snap) {
        final item = snap.data;
        if (item != null) _brand ??= item.brands.isEmpty ? '' : item.brands.first;
        return Scaffold(
          appBar: TopBar('Item details',
              trailing: CircleIcon(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  onTap: () => setState(() { _saved = !_saved; }))),
          body: snap.hasError
              ? ErrorRetry(snap.error!, () => setState(() { _item = Api.item(widget.itemId); }))
              : item == null
                  ? const Center(child: CircularProgressIndicator())
                  : _body(item),
          bottomNavigationBar: item == null
              ? null
              : BottomCta(
                  child: item.soldOut
                      ? PrimaryButton(_notify ? 'We\'ll notify you' : 'Notify me when back', onTap: () async {
                          try {
                            await Api.notifyMe(item.id);
                            if (!mounted) return;
                            setState(() { _notify = true; });
                            toast(context, 'We\'ll notify you as soon as ${item.shop} restocks it.');
                          } catch (e) {
                            if (mounted) toast(context, '$e');
                          }
                        })
                      : PrimaryButton('Add to pre-order  •  ${rs(item.price * _qty)}',
                          loading: _busy, onTap: () => _add(item)),
                ),
        );
      },
    );
  }

  Widget _body(Item item) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      Container(
        height: 200,
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.center,
        child: img(item.image, 110),
      ),
      const SizedBox(height: 20),
      Text(item.name, style: t(22, w: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('${item.shop}  •  ${item.category}', style: t(13, c: C.muted)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Text(rs(item.price),
              style: t(22, w: FontWeight.w600, c: item.soldOut ? C.ink : C.orange)),
        ),
        StockBadge(item.stockStatus),
      ]),
      const SizedBox(height: 14),
      if (item.soldOut) ..._soldOut(item) else ..._available(item),
    ]);
  }

  List<Widget> _available(Item item) => [
        if (item.stockStatus == 'low_stock')
          _note(Icons.schedule_rounded, 'Only ${item.stock} left – pre-order now to keep one for you.'),
        if (item.brands.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Choose brand', style: t(15, w: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in item.brands)
              ChoiceChipX(b, selected: b == _brand, onTap: () => setState(() { _brand = b; })),
          ]),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text('Quantity', style: t(15, w: FontWeight.w500))),
          QtyStepper(
            value: _qty,
            onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
            onPlus: _qty < item.stock ? () => setState(() => _qty++) : null,
          ),
        ]),
      ];

  // Sold-out variant (Figma "back-in-stock alert"). "Available nearby" is hardcoded.
  List<Widget> _soldOut(Item item) => [
        _note(Icons.notifications_none_rounded,
            'Sold out for now. Tap below and we\'ll notify you as soon as ${item.shop} restocks it.'),
        const SizedBox(height: 20),
        Text('Available nearby', style: t(15, w: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
          child: Row(children: [
            const ProductThumb('store', size: 48, bg: C.orangeSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Silva Grocery – Negombo', style: t(14, w: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('0.9 km  •  ${rs(item.price + 10)}', style: t(12, c: C.muted)),
              ]),
            ),
            const StockBadge('in_stock'),
          ]),
        ),
      ];

  Widget _note(IconData icon, String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.orangeSoft, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: C.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: t(13, h: 1.35))),
        ]),
      );
}
