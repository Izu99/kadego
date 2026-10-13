import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'login.dart';
import 'notifications.dart';
import 'orders.dart' show statusLabel, statusPill;
import 'store_items.dart';

/// Shop-owner home: Orders | Items | Notifications.
class StoreShell extends StatefulWidget {
  const StoreShell({super.key});
  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  int _tab = 0;
  final _ordersKey = GlobalKey<_StoreOrdersScreenState>();

  // While the Alerts tab is open, anything new counts as seen.
  void _markSeen() {
    if (_tab == 2 && Api.unread.value > 0) Api.markAllRead().catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    Api.unread.addListener(_markSeen);
  }

  @override
  void dispose() {
    Api.unread.removeListener(_markSeen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _tab, children: [
          StoreOrdersScreen(key: _ordersKey),
          const StoreItemsScreen(isHome: true),
          NotificationsScreen(
            asTab: true,
            onOpenOrder: (id) {
              setState(() => _tab = 0);
              _ordersKey.currentState?.highlight(id);
            },
          ),
        ]),
        bottomNavigationBar: KadeBottomNav(
          index: _tab,
          onTap: (i) {
            setState(() => _tab = i);
            _markSeen();
          },
          items: const [
            (Icons.receipt_long_outlined, 'Orders'),
            (Icons.inventory_2_outlined, 'Items'),
            (Icons.notifications_none_rounded, 'Alerts'),
          ],
          badges: {2: Api.unread},
        ),
      );
}

/// Incoming pre-orders for the shop (live). The owner moves each one along:
/// Confirm -> Start packing -> Mark ready -> Collected (or Cancel).
class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});
  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> with LiveReload {
  late Future<List<Order>> _orders = Api.orders();
  bool _showDone = false;
  String? _highlight, _busyId;

  static const _next = {
    'sent': ('confirmed', 'Confirm order'),
    'confirmed': ('packing', 'Start packing'),
    'packing': ('ready', 'Mark ready'),
    'ready': ('collected', 'Mark collected'),
  };

  void highlight(String id) => setState(() {
        _highlight = id;
        _showDone = false;
      });

  @override
  Future<void> liveReload() async {
    final orders = await Api.orders();
    if (mounted) setState(() { _orders = Future.value(orders); });
  }

  Future<void> _move(Order o, String status) async {
    setState(() { _busyId = o.id; });
    try {
      await Api.setOrderStatus(o.id, status);
      await liveReload();
      if (mounted) toast(context, '#${o.number}: ${statusLabel[status]}');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
    if (mounted) setState(() { _busyId = null; });
  }

  Future<void> _logout() async {
    await Api.logout();
    if (mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
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
            final all = snap.data!;
            final active = all.where((o) => o.active).toList();
            final done = all.where((o) => !o.active).toList();
            final shown = _showDone ? done : active;
            return RefreshIndicator(
              onRefresh: liveReload,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
                Row(children: [
                  Expanded(child: Text('Orders', style: t(26, w: FontWeight.w700))),
                  CircleIcon(Icons.logout_rounded, onTap: _logout),
                ]),
                const SizedBox(height: 4),
                Text(Api.user?.shop ?? '', style: t(13, c: C.muted)),
                const SizedBox(height: 16),
                Row(children: [
                  ChoiceChipX('Active (${active.length})', selected: !_showDone,
                      onTap: () => setState(() { _showDone = false; })),
                  const SizedBox(width: 8),
                  ChoiceChipX('Completed (${done.length})', selected: _showDone,
                      onTap: () => setState(() { _showDone = true; })),
                ]),
                const SizedBox(height: 16),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: [
                      img('bags', 64),
                      const SizedBox(height: 12),
                      Text(_showDone ? 'No completed orders yet' : 'No active orders right now',
                          textAlign: TextAlign.center, style: t(14, c: C.muted)),
                    ]),
                  ),
                for (final o in shown) _card(o),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Order o) {
    final next = _next[o.status];
    final busy = _busyId == o.id;
    final isNew = o.status == 'sent';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew ? C.orangeSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: o.id == _highlight ? C.orange : (isNew ? Colors.transparent : C.line), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('#${o.number}', style: t(16, w: FontWeight.w600))),
          statusPill(o.status),
        ]),
        const SizedBox(height: 4),
        Text('${o.customerName}  •  pickup ${o.pickupSlot} ${o.pickupDay}  •  ${timeAgo(o.createdAt)}',
            style: t(12, c: C.muted)),
        const SizedBox(height: 10),
        for (final l in o.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              img(l.image, 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${l.quantity} × ${l.name}${l.brand.isNotEmpty ? ' (${l.brand})' : ''}', style: t(13)),
              ),
              Text(rs(l.price * l.quantity), style: t(13, c: C.muted)),
            ]),
          ),
        const Divider(height: 20, color: C.line),
        Row(children: [
          Expanded(child: Text('${o.payment}  •  code ${o.code}', style: t(12, c: C.muted))),
          Text(rs(o.total), style: t(15, w: FontWeight.w600)),
        ]),
        if (next != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            if (['sent', 'confirmed', 'packing'].contains(o.status)) ...[
              TextButton(
                onPressed: busy ? null : () => _move(o, 'cancelled'),
                child: Text('Cancel', style: t(14, w: FontWeight.w500, c: C.red)),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: PrimaryButton(next.$2, loading: busy, onTap: () => _move(o, next.$1))),
          ]),
        ],
      ]),
    );
  }
}
