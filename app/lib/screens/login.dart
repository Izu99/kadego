import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'store_orders.dart';

/// Sends the user to the right side of the app for their role.
void openHomeFor(BuildContext context, User user) {
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => user.isStore ? const StoreShell() : const MainShell()),
    (_) => false,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _hide = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; });
    try {
      final user = await Api.login(_phone.text.trim(), _password.text);
      if (mounted) openHomeFor(context, user);
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() { _busy = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const AuthHeader(title: 'Welcome back', subtitle: 'Log in to pre-order from your local kade.'),
            const SizedBox(height: 28),
            AuthField(
              controller: _phone,
              label: 'Phone number',
              hint: '077 123 4567',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Enter your phone number' : null,
            ),
            AuthField(
              controller: _password,
              label: 'Password',
              hint: 'Your password',
              icon: Icons.lock_outline_rounded,
              obscure: _hide,
              onToggleObscure: () => setState(() { _hide = !_hide; }),
              validator: (v) => v!.isEmpty ? 'Enter your password' : null,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 8),
            PrimaryButton('Log in', loading: _busy, onTap: _login),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('New to KadeGo? ', style: t(14, c: C.muted)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text('Create account', style: t(14, w: FontWeight.w600, c: C.orange)),
              ),
            ]),
            const SizedBox(height: 28),
            const _DemoAccounts(),
          ]),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; });
    try {
      final user = await Api.register(_name.text.trim(), _phone.text.trim(), _password.text);
      if (mounted) openHomeFor(context, user);
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() { _busy = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar('Create account'),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
          Text('Sign up as a customer to start pre-ordering.', style: t(14, c: C.muted)),
          const SizedBox(height: 20),
          AuthField(
            controller: _name,
            label: 'Full name',
            hint: 'e.g. Dilini Fernando',
            icon: Icons.person_outline_rounded,
            validator: (v) => v!.trim().isEmpty ? 'Enter your name' : null,
          ),
          AuthField(
            controller: _phone,
            label: 'Phone number',
            hint: '077 123 4567',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            validator: (v) => v!.trim().length < 9 ? 'Enter a valid phone number' : null,
          ),
          AuthField(
            controller: _password,
            label: 'Password',
            hint: 'At least 4 characters',
            icon: Icons.lock_outline_rounded,
            obscure: _hide,
            onToggleObscure: () => setState(() { _hide = !_hide; }),
            validator: (v) => v!.length < 4 ? 'At least 4 characters' : null,
          ),
        ]),
      ),
      bottomNavigationBar: BottomCta(child: PrimaryButton('Create account', loading: _busy, onTap: _register)),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String title, subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
        decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: img('bags', 46),
          ),
          const SizedBox(height: 14),
          Text(title, style: t(28, w: FontWeight.w700, c: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: t(14, c: Colors.white)),
        ]),
      );
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t(14, w: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboard,
            obscureText: obscure,
            onFieldSubmitted: onSubmitted,
            style: t(15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: t(15, c: C.faint),
              prefixIcon: Icon(icon, color: C.muted, size: 20),
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: C.muted, size: 20),
                    ),
              filled: true,
              fillColor: C.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.orange, width: 1.5)),
            ),
          ),
        ]),
      );
}

/// Demo logins shown on the login screen so testers know what to use.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Demo accounts', style: t(13, w: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Customer:  0771234567  /  1234', style: t(12, c: C.muted)),
          const SizedBox(height: 2),
          Text('Shop owner:  0770000000  /  1234', style: t(12, c: C.muted)),
        ]),
      );
}
