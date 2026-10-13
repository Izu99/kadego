import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cart.dart';

void openOrder(BuildContext context, String orderId) => Navigator.of(context, rootNavigator: true)
    .push(MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)));

const statusLabel = {
  'sent': 'Order sent',
  'confirmed': 'Confirmed',
  'packing': 'Being packed',
  'ready': 'Ready for pickup',
  'collected': 'Collected',
  'cancelled': 'Cancelled',
};

Widget statusPill(String status) => switch (status) {
      'ready' => const Pill('Ready for pickup', fg: C.green, bg: C.greenSoft, dot: true),
      'collected' => const Pill('Collected', fg: C.muted, bg: C.surface),
      'cancelled' => const Pill('Cancelled', fg: C.red, bg: C.redSoft),
      _ => Pill(statusLabel[status]!, fg: C.orange, bg: C.orangeSoft, dot: true),
    };

/// Orders tab — the customer's pre-orders (live).
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with LiveReload {
  late Future<List<Order>> _orders = Api.orders();

  @override
  Future<void> liveReload() async {
    final orders = await Api.orders();
    if (mounted) setState(() { _orders = Future.value(orders); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Order>>(
          future: _orders,
          builder: (context, snap) {
            if (snap.hasError && !snap.hasData) {
              return ErrorRetry(snap.error!, () => setState(() { _orders = Api.orders(); }));
            }
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final orders = snap.data!;
            if (orders.isEmpty) return const _NoOrders();
            return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
              Text('My orders', style: t(26, w: FontWeight.w700)),
              const SizedBox(height: 16),
              for (final o in orders) _card(o),
            ]);
          },
        ),
      ),
    );
  }

  Widget _card(Order o) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: o.active ? C.orangeSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openOrder(context, o.id),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: o.active ? null : Border.all(color: C.line),
              ),
              child: Row(children: [
                const ProductThumb('store', size: 48, bg: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('#${o.number}  •  ${o.shop}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: t(15, w: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('${o.itemCount} item${o.itemCount == 1 ? '' : 's'}  •  ${rs(o.total)}  •  ${o.pickupSlot} ${o.pickupDay}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: t(12, c: C.muted)),
                    const SizedBox(height: 6),
                    statusPill(o.status),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.muted),
              ]),
            ),
          ),
        ),
      );
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ValueListenableBuilder<int>(
            valueListenable: Api.cartCount,
            builder: (context, n, _) => Column(mainAxisSize: MainAxisSize.min, children: [
              img('bags', 72),
              const SizedBox(height: 14),
              Text('No pre-orders yet', style: t(17, w: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                  n > 0
                      ? 'You have $n item${n == 1 ? '' : 's'} waiting in your pre-order.'
                      : 'Pre-order from a shop and track it here.',
                  textAlign: TextAlign.center,
                  style: t(13, c: C.muted)),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: PrimaryButton(n > 0 ? 'View my pre-order' : 'Browse shops', onTap: () {
                  if (n > 0) {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const CartScreen()));
                  } else {
                    MainShell.tab.value = 0;
                  }
                }),
              ),
            ]),
          ),
        ),
      );
}

/// Order status — live from the server; moves on as the shop updates the order.
class OrderStatusScreen extends StatefulWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});
  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> with LiveReload {
  late Future<Order> _order = Api.order(widget.orderId);

  @override
  Future<void> liveReload() async {
    final o = await Api.order(widget.orderId);
    if (mounted) setState(() { _order = Future.value(o); });
  }

  static const _steps = [
    ('sent', 'Order sent', 'Waiting for the shop to confirm'),
    ('confirmed', 'Shop confirmed', 'The shop accepted your order'),
    ('packing', 'Being packed', 'Your items are being packed now'),
    ('ready', 'Ready for pickup', 'Show your code at the counter'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar('Order status'),
      body: FutureBuilder<Order>(
        future: _order,
        builder: (context, snap) {
          if (snap.hasError && !snap.hasData) {
            return ErrorRetry(snap.error!, () => setState(() { _order = Api.order(widget.orderId); }));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return _body(snap.data!);
        },
      ),
    );
  }

  Widget _body(Order o) {
    final reached = _steps.indexWhere((s) => s.$1 == o.status);
    final current = o.status == 'collected' ? _steps.length : reached; // collected = all done
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: o.status == 'cancelled' ? C.redSoft : C.orangeSoft, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              switch (o.status) {
                'cancelled' => 'Order cancelled',
                'collected' => 'Picked up – thank you!',
                _ => 'Pickup ${o.pickupDay} at ${o.pickupSlot}',
              },
              style: t(20, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Order #${o.number}  •  ${o.shop}', style: t(13, c: C.muted)),
          if (o.active) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Text('Show this code at the counter', style: t(13, c: C.muted))),
                Text(o.code, style: t(24, w: FontWeight.w700, c: C.orange).copyWith(letterSpacing: 4)),
              ]),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 20),
      if (o.status != 'cancelled')
        for (var i = 0; i < _steps.length; i++)
          _Step(
            _steps[i].$2,
            o.reachedAt[_steps[i].$1] != null
                ? '${clock(o.reachedAt[_steps[i].$1]!)}  •  ${_steps[i].$3}'
                : _steps[i].$3,
            state: i < current || (i == current && o.status == 'ready') ? 2 : (i == current ? 1 : 0),
            last: i == _steps.length - 1,
          ),
      const SizedBox(height: 4),
      Text('Your items', style: t(15, w: FontWeight.w500)),
      const SizedBox(height: 8),
      for (final l in o.lines)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            ProductThumb(l.image, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${l.name}${l.brand.isNotEmpty ? ' • ${l.brand}' : ''}  × ${l.quantity}',
                  style: t(14)),
            ),
            Text(rs(l.price * l.quantity), style: t(14, w: FontWeight.w500)),
          ]),
        ),
      const Divider(height: 24, color: C.line),
      Row(children: [
        Expanded(child: Text('Total  •  ${o.payment}', style: t(14, c: C.muted))),
        Text(rs(o.total), style: t(16, w: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: C.orange.withValues(alpha: .08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const ProductThumb('store', size: 48, bg: C.orangeSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.shop, style: t(15, w: FontWeight.w500)),
              Text('Main Street, Negombo', style: t(12, c: C.muted)),
            ]),
          ),
          Material(
            color: C.orange,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => toast(context, 'Calling ${o.shop}...'),
              child: const SizedBox(width: 44, height: 44, child: Icon(Icons.call_outlined, color: Colors.white, size: 20)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _Step extends StatelessWidget {
  final String title, sub;
  final int state; // 2 done, 1 current, 0 upcoming
  final bool last;
  const _Step(this.title, this.sub, {required this.state, this.last = false});

  @override
  Widget build(BuildContext context) {
    final dot = switch (state) {
      2 => Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18)),
      1 => Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.orange, width: 2.5))),
      _ => Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.faint, width: 1.5))),
    };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          dot,
          if (!last) Expanded(child: Container(width: 2, color: state == 2 ? C.green : C.line)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: t(15, w: FontWeight.w500, c: state == 1 ? C.orange : (state == 0 ? C.muted : C.ink))),
              const SizedBox(height: 2),
              Text(sub, style: t(12, c: C.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}
