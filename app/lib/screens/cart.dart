import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'pickup_time.dart';

/// "My pre-order" — customer cart CRUD (read, update quantity, delete).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with LiveReload {
  late Future<Cart> _cart = Api.cart();

  void _reload() => setState(() { _cart = Api.cart(); });

  @override
  Future<void> liveReload() async {
    final cart = await Api.cart();
    if (mounted) setState(() { _cart = Future.value(cart); });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
    _reload();
  }

  void _change(CartLine l, int delta) {
    final q = l.quantity + delta;
    if (q < 1) return _remove(l);
    if (q > l.item.stock) return toast(context, 'Only ${l.item.stock} left in stock');
    _run(() => Api.setQuantity(l.id, q));
  }

  void _remove(CartLine l) => _run(() async {
        await Api.removeFromCart(l.id);
        if (mounted) toast(context, '${l.item.name} removed');
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cart>(
      future: _cart,
      builder: (context, snap) {
        final cart = snap.data;
        return Scaffold(
          appBar: const TopBar('My pre-order'),
          body: snap.hasError
              ? ErrorRetry(snap.error!, _reload)
              : cart == null
                  ? const Center(child: CircularProgressIndicator())
                  : cart.lines.isEmpty
                      ? _empty()
                      : _body(cart),
          bottomNavigationBar: cart == null || cart.lines.isEmpty
              ? null
              : BottomCta(
                  child: PrimaryButton('Choose pickup time', onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => PickupTimeScreen(total: cart.total)));
                    if (mounted) _reload();
                  }),
                ),
        );
      },
    );
  }

  Widget _empty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          img('cart', 72),
          const SizedBox(height: 14),
          Text('Your pre-order is empty', style: t(16, w: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Add items from a shop to get started.', style: t(13, c: C.muted)),
        ]),
      );

  Widget _body(Cart cart) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.storefront_outlined, color: C.orange, size: 20),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Perera Stores', style: t(14, w: FontWeight.w500)),
              Text('Pickup only  •  Main Street, Negombo', style: t(12, c: C.muted)),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        for (final l in cart.lines)
          Dismissible(
            key: ValueKey(l.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete_outline_rounded, color: C.red),
            ),
            onDismissed: (_) => _remove(l),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                ProductThumb(l.item.image, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.item.name, style: t(15, w: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(l.brand.isNotEmpty ? l.brand : l.item.description, style: t(12, c: C.muted)),
                    const SizedBox(height: 4),
                    Text(rs(l.item.price * l.quantity), style: t(14, w: FontWeight.w600, c: C.orange)),
                  ]),
                ),
                QtyStepper(value: l.quantity, onMinus: () => _change(l, -1), onPlus: () => _change(l, 1)),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            _sum('Subtotal', rs(cart.subtotal)),
            const SizedBox(height: 10),
            _sum('Pickup fee', 'Free'),
            const Divider(height: 26, color: C.line),
            _sum('Total', rs(cart.total), bold: true),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Swipe left on an item to remove it.', textAlign: TextAlign.center, style: t(12, c: C.faint)),
      ]);

  Widget _sum(String a, String b, {bool bold = false}) => Row(children: [
        Expanded(child: Text(a, style: t(bold ? 16 : 14, w: bold ? FontWeight.w600 : FontWeight.w400, c: bold ? C.ink : C.muted))),
        Text(b, style: t(bold ? 16 : 14, w: bold ? FontWeight.w600 : FontWeight.w400)),
      ]);
}
