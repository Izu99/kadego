import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/home.dart';
import 'screens/language.dart';
import 'screens/login.dart';
import 'screens/orders.dart';
import 'screens/profile.dart';
import 'screens/shop.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  Api.startLiveUpdates();
  runApp(const KadeGoApp());
}

class KadeGoApp extends StatelessWidget {
  const KadeGoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KadeGo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => _PhoneFrame(child: child!),
        home: const _StartGate(),
      );
}

/// Keeps the layout phone-sized on tablets / laptops / browser, and stops very large
/// system font settings from breaking fixed-size controls.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});
  static const maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scaled = MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25)),
      child: child,
    );
    if (mq.size.width <= maxWidth) return scaled;
    return ColoredBox(
      color: C.surface,
      child: Center(
        child: Container(
          width: maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: C.orange.withValues(alpha: .08), blurRadius: 40)],
          ),
          child: MediaQuery(
            data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
            child: ClipRect(child: scaled),
          ),
        ),
      ),
    );
  }
}

/// On launch: go straight in if a login was saved, otherwise show the language screen.
class _StartGate extends StatefulWidget {
  const _StartGate();
  @override
  State<_StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<_StartGate> {
  @override
  void initState() {
    super.initState();
    Api.restore().then((user) {
      if (!mounted) return;
      if (user != null) return openHomeFor(context, user);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: C.orange, body: Center(child: CircularProgressIndicator(color: Colors.white)));
}

/// Bottom-nav shell. The Home tab has its own navigator so the shop page keeps the nav bar (as in Figma).
class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});
  static final tab = ValueNotifier<int>(0);
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _homeNav = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    MainShell.tab.value = widget.initialTab;
    Api.cart().catchError((_) => Cart.fromJson({'items': [], 'subtotal': 0, 'total': 0}));
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: MainShell.tab,
        builder: (context, index, _) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (index == 0 && (_homeNav.currentState?.canPop() ?? false)) {
              _homeNav.currentState!.pop();
            } else if (index != 0) {
              MainShell.tab.value = 0;
            }
          },
          child: Scaffold(
            body: IndexedStack(index: index, children: [
              Navigator(
                key: _homeNav,
                onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
              const ShopScreen(showBack: false),
              const OrdersTab(),
              const ProfileScreen(),
            ]),
            bottomNavigationBar: KadeBottomNav(
              index: index,
              badges: {2: Api.cartCount},
              onTap: (i) {
                if (i == index && i == 0) _homeNav.currentState?.popUntil((r) => r.isFirst);
                MainShell.tab.value = i;
              },
            ),
          ),
        ),
      );
}
