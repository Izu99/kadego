import 'package:flutter/material.dart';

import 'login.dart';
import '../theme.dart';
import '../widgets.dart';

class LanguageScreen extends StatefulWidget {
  final bool fromProfile;
  const LanguageScreen({super.key, this.fromProfile = false});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _lang = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: img('bags', 56),
              ),
              const SizedBox(height: 18),
              Text('KadeGo', style: t(36, w: FontWeight.w700, c: Colors.white)),
              const SizedBox(height: 12),
              Text('Pre-order from your local kade.\nSkip the queue, pick up when it\'s quiet.',
                  textAlign: TextAlign.center, style: t(15, c: Colors.white, h: 1.35)),
            ]),
          ),
          const SizedBox(height: 28),
          Text('Choose your language', style: t(19, w: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('You can change this any time in Profile.', style: t(13, c: C.muted)),
          const SizedBox(height: 18),
          _option('Sinhala'),
          _option('தமிழ்', sub: 'Tamil'),
          _option('English'),
        ]),
      ),
      bottomNavigationBar: BottomCta(
        child: PrimaryButton(widget.fromProfile ? 'Save' : 'Get started', onTap: () {
          if (widget.fromProfile) return Navigator.pop(context);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }),
      ),
    );
  }

  Widget _option(String label, {String? sub}) {
    final on = _lang == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() { _lang = label; });
          // Only English is translated for now; the other options are shown for the design.
          if (label != 'English') toast(context, 'Coming soon – English will be used for now');
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: on ? C.orangeSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? C.orange : C.line, width: on ? 1.8 : 1),
          ),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: t(17, w: on ? FontWeight.w500 : FontWeight.w400)),
                if (sub != null) Text(sub, style: t(12, c: C.muted)),
              ]),
            ),
            RadioTick(on),
          ]),
        ),
      ),
    );
  }
}
