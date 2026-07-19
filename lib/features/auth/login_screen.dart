import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';
import 'register_screen.dart';

/// Email/password sign-in with a language switcher in the header so users can
/// pick Arabic / Kurdish / English before they even log in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _signIn() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AuthService.signIn(_email.text, _password.text);
      // AuthGate reacts to the auth stream; no manual navigation needed.
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, e.message ?? tr(context).error);
    } catch (_) {
      if (mounted) showSnack(context, tr(context).error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final lp = context.watch<LocaleProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Brand header ----
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: MeezanTheme.navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      const Icon(Icons.balance,
                          size: 56, color: MeezanTheme.gold),
                      const SizedBox(height: 8),
                      Text(t.appTitle,
                          style: const TextStyle(
                              color: MeezanTheme.gold,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4)),
                      const SizedBox(height: 4),
                      Text(t.tagline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // ---- Language switcher ----
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                      ButtonSegment(value: 'ckb', label: Text('کوردی')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {lp.locale.languageCode},
                    onSelectionChanged: (s) =>
                        context.read<LocaleProvider>().setLocale(s.first),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                        labelText: t.email,
                        prefixIcon: const Icon(Icons.mail_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    onSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                        labelText: t.password,
                        prefixIcon: const Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(t.signIn),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: Text(t.noAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
