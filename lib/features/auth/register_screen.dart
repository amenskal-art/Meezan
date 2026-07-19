import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/locale_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Registration with the Client/Lawyer role selector required by the spec.
/// Lawyers additionally pick a specialization; everyone picks a governorate.
/// Lawyer accounts are created with status = 'pending' (see AuthService +
/// firestore.rules) and go straight to the verification upload flow.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'client';
  String _governorate = 'baghdad';
  String _specialization = Specializations.codes.first;
  bool _busy = false;

  Future<void> _register() async {
    final t = tr(context);
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 6) {
      showSnack(context, t.error);
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.register(
        email: _email.text,
        password: _password.text,
        role: _role,
        name: _name.text,
        phone: _phone.text,
        governorate: _governorate,
        specialization: _specialization,
        language: context.read<LocaleProvider>().locale.languageCode,
      );
      if (mounted) Navigator.of(context).pop(); // AuthGate takes over routing.
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, e.message ?? t.error);
    } catch (_) {
      if (mounted) showSnack(context, t.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _roleCard(String role, IconData icon, String title, String desc) {
    final selected = _role == role;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _role = role),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? MeezanTheme.navy
                : MeezanTheme.navy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? MeezanTheme.gold : Colors.transparent,
                width: 2),
          ),
          child: Column(children: [
            Icon(icon,
                size: 32,
                color: selected ? MeezanTheme.gold : MeezanTheme.navy),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : MeezanTheme.navy)),
            const SizedBox(height: 2),
            Text(desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : Colors.blueGrey)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.createAccount)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.chooseRole,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(children: [
                    _roleCard('client', Icons.person_outline, t.roleClient,
                        t.roleClientDesc),
                    const SizedBox(width: 12),
                    _roleCard('lawyer', Icons.gavel_outlined, t.roleLawyer,
                        t.roleLawyerDesc),
                  ]),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _name,
                      decoration: InputDecoration(
                          labelText: t.fullName,
                          prefixIcon: const Icon(Icons.badge_outlined))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                          labelText: t.email,
                          prefixIcon: const Icon(Icons.mail_outline))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                          labelText: t.phone,
                          prefixIcon: const Icon(Icons.phone_outlined))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _password,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                          labelText: t.password,
                          prefixIcon: const Icon(Icons.lock_outline))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _governorate,
                    decoration: InputDecoration(
                        labelText: t.governorate,
                        prefixIcon: const Icon(Icons.location_on_outlined)),
                    items: [
                      for (final c in Governorates.codes)
                        DropdownMenuItem(
                            value: c, child: Text(Governorates.label(c, lang))),
                    ],
                    onChanged: (v) =>
                        setState(() => _governorate = v ?? 'baghdad'),
                  ),
                  if (_role == 'lawyer') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _specialization,
                      decoration: InputDecoration(
                          labelText: t.specialization,
                          prefixIcon: const Icon(Icons.school_outlined)),
                      items: [
                        for (final c in Specializations.codes)
                          DropdownMenuItem(
                              value: c,
                              child: Text(Specializations.label(c, lang))),
                      ],
                      onChanged: (v) => setState(
                          () => _specialization = v ?? _specialization),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _register,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(t.createAccount),
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.haveAccount)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
