import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

/// Keeps a screen in sync with the server: on every [Api.tick] it calls [liveReload].
/// Failures are ignored (the next tick tries again), so there is no flicker or error flash.
mixin LiveReload<T extends StatefulWidget> on State<T> {
  bool _fetching = false;

  /// Fetch fresh data and setState with it.
  Future<void> liveReload();

  void _onTick() {
    if (!mounted || _fetching) return;
    _fetching = true;
    liveReload().catchError((_) {}).whenComplete(() => _fetching = false);
  }

  @override
  void initState() {
    super.initState();
    Api.tick.addListener(_onTick);
  }

  @override
  void dispose() {
    Api.tick.removeListener(_onTick);
    super.dispose();
  }
}

Widget img(String key, double size) => Image.asset('assets/img/$key.png', width: size, height: size,
    errorBuilder: (_, __, ___) => Image.asset('assets/img/other.png', width: size, height: size));

void toast(BuildContext context, String msg, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), action: action, duration: const Duration(seconds: 2)));
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  const PrimaryButton(this.label, {super.key, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: loading ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: C.orange,
            disabledBackgroundColor: C.orange.withValues(alpha: .6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: t(16, w: FontWeight.w600, c: Colors.white))),
        ),
      );
}

/// Button pinned at the bottom of a screen, like the Figma CTAs.
class BottomCta extends StatelessWidget {
  final Widget child;
  const BottomCta({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: child));
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  const CircleIcon(this.icon, {super.key, this.onTap, this.size = 44});
  @override
  Widget build(BuildContext context) => Material(
        color: C.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: 20, color: C.ink)),
        ),
      );
}

/// Back button + centred title (+ optional right button).
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final IconData backIcon;
  const TopBar(this.title, {super.key, this.trailing, this.onBack, this.backIcon = Icons.chevron_left_rounded});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            CircleIcon(backIcon, onTap: onBack ?? () => Navigator.maybePop(context)),
            Expanded(
                child: Text(title,
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(17, w: FontWeight.w500))),
            trailing ?? const SizedBox(width: 44),
          ]),
        ),
      );
}

class StockBadge extends StatelessWidget {
  final String status; // in_stock / low_stock / sold_out
  final bool dot;
  const StockBadge(this.status, {super.key, this.dot = true});
  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      'low_stock' => ('Low stock', C.amber, C.amberSoft),
      'sold_out' => ('Sold out', C.red, C.redSoft),
      'busy' => ('Busy now', C.red, C.redSoft),
      'quiet' => ('Quiet now', C.green, C.greenSoft),
      _ => ('In stock', C.green, C.greenSoft),
    };
    return Pill(label, fg: fg, bg: bg, dot: dot);
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  final bool dot;
  const Pill(this.label, {super.key, required this.fg, required this.bg, this.dot = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label, style: t(12, w: FontWeight.w500, c: fg)),
        ]),
      );
}

/// Orange (selected) or grey chip used for categories, brands, Today/Tomorrow.
class ChoiceChipX extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChoiceChipX(this.label, {super.key, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: selected ? C.orange : C.surface, borderRadius: BorderRadius.circular(24)),
          child: Text(label, style: t(14, w: FontWeight.w500, c: selected ? Colors.white : C.ink)),
        ),
      );
}

class ProductThumb extends StatelessWidget {
  final String image;
  final double size;
  final Color bg;
  const ProductThumb(this.image, {super.key, this.size = 52, this.bg = C.surface});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: img(image, size * .6),
      );
}

class RoundAdd extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  const RoundAdd({super.key, this.icon = Icons.add_rounded, this.onTap, this.filled = true, this.size = 34});
  @override
  Widget build(BuildContext context) => Material(
        color: filled ? C.orange : C.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
              width: size, height: size, child: Icon(icon, size: 20, color: filled ? Colors.white : C.ink)),
        ),
      );
}

/// − 1 + stepper
class QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus, onPlus;
  const QtyStepper({super.key, required this.value, this.onMinus, this.onPlus});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        RoundAdd(icon: Icons.remove_rounded, filled: false, onTap: onMinus),
        SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.center, style: t(15, w: FontWeight.w500))),
        RoundAdd(onTap: onPlus),
      ]);
}

class RadioTick extends StatelessWidget {
  final bool on;
  const RadioTick(this.on, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? C.orange : Colors.transparent,
          border: on ? null : Border.all(color: C.faint, width: 1.5),
        ),
        child: on ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
      );
}

/// Section header: "Categories ........ See all"
class SectionHead extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHead(this.title, {super.key, this.onSeeAll});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: t(17, w: FontWeight.w500))),
        if (onSeeAll != null)
          GestureDetector(onTap: onSeeAll, child: Text('See all', style: t(14, c: C.orange))),
      ]);
}

class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetry(this.error, this.onRetry, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, color: C.faint, size: 40),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center, style: t(14, c: C.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}

class KadeBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> items;
  final Map<int, ValueListenable<int>> badges; // tab index -> count shown as a dot
  const KadeBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    this.items = customerTabs,
    this.badges = const {},
  });

  static const customerTabs = [
    (Icons.home_outlined, 'Home'),
    (Icons.search_rounded, 'Explore'),
    (Icons.receipt_long_outlined, 'Orders'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: C.line))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(items.length, (i) {
                final on = i == index;
                final color = on ? C.orange : C.faint;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(items[i].$1, color: color, size: 24),
                        if (badges[i] != null) Positioned(right: -8, top: -4, child: CountBadge(badges[i]!)),
                      ]),
                      const SizedBox(height: 3),
                      Text(items[i].$2, style: t(11, w: on ? FontWeight.w600 : FontWeight.w400, c: color)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      );
}

/// Small orange count bubble; hidden at 0.
class CountBadge extends StatelessWidget {
  final ValueListenable<int> count;
  const CountBadge(this.count, {super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: count,
        builder: (_, n, _) => n == 0
            ? const SizedBox.shrink()
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(10)),
                child: Text(n > 99 ? '99+' : '$n', textAlign: TextAlign.center, style: t(10, w: FontWeight.w700, c: Colors.white)),
              ),
      );
}

/// Bell button with the unread-notifications badge.
class BellButton extends StatelessWidget {
  final VoidCallback onTap;
  const BellButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        CircleIcon(Icons.notifications_none_rounded, onTap: onTap),
        Positioned(right: -2, top: -2, child: IgnorePointer(child: CountBadge(Api.unread))),
      ]);
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && DateTime.now().day == d.day) return clock(d);
  if (diff.inDays < 2) return 'Yesterday';
  return '${d.day}/${d.month}/${d.year}';
}

String clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}
