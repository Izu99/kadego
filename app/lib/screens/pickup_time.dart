import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'orders.dart';

/// Pickup time + payment. Slots and payment are hardcoded; placing the order clears the cart.
class PickupTimeScreen extends StatefulWidget {
  final num total;
  const PickupTimeScreen({super.key, required this.total});
  @override
  State<PickupTimeScreen> createState() => _PickupTimeScreenState();
}

class _PickupTimeScreenState extends State<PickupTimeScreen> {
  bool _today = true;
  String _slot = '4:30 pm';
  String _pay = 'Cash at pickup';
  bool _busy = false;

  static const _slots = [
    ('4:00 pm', 'Quiet'), ('4:30 pm', 'Quiet'), ('5:00 pm', 'Moderate'), ('5:30 pm', 'Busy'),
    ('6:00 pm', 'Busy'), ('6:30 pm', 'Busy'), ('7:00 pm', 'Moderate'), ('7:30 pm', 'Quiet'),
  ];

  Color _levelColor(String l) => switch (l) { 'Quiet' => C.green, 'Moderate' => C.amber, _ => C.red };

  Future<void> _place() async {
    setState(() { _busy = true; });
    try {
      final order = await Api.placeOrder(day: _today ? 'today' : 'tomorrow', slot: _slot, payment: _pay);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      MainShell.tab.value = 2; // Orders tab
      openOrder(context, order.id);
    } catch (e) {
      if (mounted) toast(context, '$e');
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar('Pickup time'),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [_tab('Today', true), _tab('Tomorrow', false)]),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 6,
          spacing: 12,
          children: [
            Text('Pick a time slot', style: t(16, w: FontWeight.w500)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (final l in const ['Quiet', 'Moderate', 'Busy']) ...[
                const SizedBox(width: 8),
                Container(width: 7, height: 7, decoration: BoxDecoration(color: _levelColor(l), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(l, style: t(11, c: C.muted)),
              ],
            ]),
          ],
        ),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 62),
          children: [for (final s in _slots) _slotTile(s.$1, s.$2)],
        ),
        const SizedBox(height: 24),
        Text('Payment', style: t(16, w: FontWeight.w500)),
        const SizedBox(height: 12),
        for (final p in const ['Cash at pickup', 'Card', 'Payment app (FriMi, Genie)']) _payOption(p),
      ]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: Text('Total  •  pickup $_slot ${_today ? 'today' : 'tomorrow'}', style: t(13, c: C.muted))),
              Text(rs(widget.total), style: t(14, w: FontWeight.w500)),
            ]),
            const SizedBox(height: 12),
            PrimaryButton('Place pre-order', loading: _busy, onTap: _place),
          ]),
        ),
      ),
    );
  }

  Widget _tab(String label, bool today) {
    final on = _today == today;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _today = today; }),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label, style: t(14, w: on ? FontWeight.w500 : FontWeight.w400, c: on ? C.ink : C.muted)),
        ),
      ),
    );
  }

  Widget _slotTile(String time, String level) {
    final on = _slot == time;
    return GestureDetector(
      onTap: () => setState(() { _slot = time; }),
      child: Container(
        decoration: BoxDecoration(
          color: on ? C.orangeSoft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? C.orange : C.line, width: on ? 1.6 : 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(time, style: t(14, w: FontWeight.w500, c: on ? C.orange : C.ink))),
          const SizedBox(height: 2),
          Text(level, style: t(11, c: _levelColor(level))),
        ]),
      ),
    );
  }

  Widget _payOption(String label) {
    final on = _pay == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() { _pay = label; }),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: on ? C.orangeSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? C.orange : C.line, width: on ? 1.6 : 1),
          ),
          child: Row(children: [Expanded(child: Text(label, style: t(14))), RadioTick(on)]),
        ),
      ),
    );
  }
}
