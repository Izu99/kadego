import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'language.dart';
import 'notifications.dart';
import 'login.dart';

/// Profile — name/phone come from the logged-in account; the rest is hardcoded.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _logout(BuildContext context) async {
    await Api.logout();
    MainShell.tab.value = 0;
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Api.user;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          Row(children: [
            Expanded(child: Text('Profile', style: t(26, w: FontWeight.w700))),
            const CircleIcon(Icons.settings_outlined),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.orangeSoft, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(user?.initials ?? '', style: t(20, w: FontWeight.w600, c: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '', style: t(18, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${user?.phone ?? ''}  •  Negombo', style: t(13, c: C.muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _group([
            _Row(Icons.receipt_long_outlined, 'My orders', '', onTap: () => MainShell.tab.value = 2),
            const _Row(Icons.favorite_border_rounded, 'Saved shops', 'Perera Stores, +1'),
            _Row(Icons.language_rounded, 'Language', 'English', onTap: () => _push(context, const LanguageScreen(fromProfile: true))),
            _Row(Icons.notifications_none_rounded, 'Notifications', 'On',
                onTap: () => _push(context, const NotificationsScreen())),
            const _Row(Icons.help_outline_rounded, 'Help & support', ''),
          ]),
          const SizedBox(height: 16),
          Material(
            color: C.redSoft,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _logout(context),
              child: SizedBox(
                height: 50,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout_rounded, color: C.orange, size: 20),
                  const SizedBox(width: 8),
                  Text('Log out', style: t(15, w: FontWeight.w500, c: C.orange)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: C.line),
            rows[i],
          ],
        ]),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  const _Row(this.icon, this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap ?? () => toast(context, '$label – coming soon'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(children: [
            Icon(icon, size: 20, color: C.ink),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(15))),
            Expanded(
              flex: 2,
              child: Text(value,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: t(13, c: C.muted)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: C.muted, size: 20),
          ]),
        ),
      );
}
