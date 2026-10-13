import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'item_details.dart';
import 'orders.dart';

/// Notifications for the logged-in user (customer or shop owner), live from the server.
class NotificationsScreen extends StatefulWidget {
  /// Shown as a tab (no back button) on the store side.
  final bool asTab;
  /// Store side: what to do when an order notification is tapped.
  final void Function(String orderId)? onOpenOrder;
  const NotificationsScreen({super.key, this.asTab = false, this.onOpenOrder});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with LiveReload {
  late Future<List<AppNotification>> _items = _load();

  Future<List<AppNotification>> _load() async {
    final items = await Api.notifications();
    // Opened = seen (the unread dots stay for this visit). As a tab, the shell decides when it is visible.
    if (!widget.asTab && Api.unread.value > 0) Api.markAllRead();
    return items;
  }

  @override
  Future<void> liveReload() async {
    final items = await _load();
    if (mounted) setState(() { _items = Future.value(items); });
  }

  void _open(AppNotification n) {
    if (n.orderId != null) {
      widget.onOpenOrder != null ? widget.onOpenOrder!(n.orderId!) : openOrder(context, n.orderId!);
    } else if (n.itemId != null) {
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => ItemDetailsScreen(itemId: n.itemId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<AppNotification>>(
      future: _items,
      builder: (context, snap) {
        if (snap.hasError && !snap.hasData) {
          return ErrorRetry(snap.error!, () => setState(() { _items = _load(); }));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.notifications_none_rounded, size: 56, color: C.faint),
              const SizedBox(height: 10),
              Text('No notifications yet', style: t(16, w: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Order updates and stock alerts show up here.', style: t(13, c: C.muted)),
            ]),
          );
        }
        final now = DateTime.now();
        bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
        final today = items.where((n) => isToday(n.createdAt)).toList();
        final earlier = items.where((n) => !isToday(n.createdAt)).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          if (today.isNotEmpty) ...[
            Text('Today', style: t(13, c: C.muted)),
            const SizedBox(height: 10),
            for (final n in today) _Note(n, onTap: () => _open(n)),
          ],
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Earlier', style: t(13, c: C.muted)),
            const SizedBox(height: 10),
            for (final n in earlier) _Note(n, onTap: () => _open(n)),
          ],
        ]);
      },
    );

    if (!widget.asTab) return Scaffold(appBar: const TopBar('Notifications'), body: body);
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text('Notifications', style: t(26, w: FontWeight.w700)),
          ),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _Note(this.n, {required this.onTap});

  String? get _link => switch (n.type) {
        'back_in_stock' => 'Pre-order now',
        'new_order' => 'Open order',
        _ => n.orderId != null ? 'View order' : null,
      };

  @override
  Widget build(BuildContext context) {
    final unread = !n.read;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: unread ? C.orangeSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: unread ? null : Border.all(color: C.line),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: unread ? Colors.white : C.surface, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: img(n.image, 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(n.title, style: t(14, w: FontWeight.w500))),
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(top: 5, left: 6),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(n.body, style: t(12, c: C.muted, h: 1.35)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(timeAgo(n.createdAt), style: t(11, c: C.faint)),
                    if (_link != null) ...[
                      const SizedBox(width: 12),
                      Text(_link!, style: t(12, w: FontWeight.w500, c: C.orange)),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
