import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_provider.dart';
import '../../core/models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Settings: language selection (Arabic / Kurdish Sorani / English — persisted
/// to users/{uid}.language so it follows the account across devices), basic
/// profile editing, and sign-out.
class SettingsScreen extends StatefulWidget {
  final AppUser user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone);
  late final TextEditingController _bio =
      TextEditingController(text: widget.user.bio);
  bool _busy = false;

  Future<void> _setLanguage(String code) async {
    context.read<LocaleProvider>().setLocale(code);
    // Persist so RoleGate restores it on the next login / device.
    await FirestoreService.updateUser(widget.user.uid, {'language': code});
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await FirestoreService.updateUser(widget.user.uid, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'bio': _bio.text.trim(),
      });
      if (mounted) showSnack(context, tr(context).ok);
    } catch (_) {
      if (mounted) showSnack(context, tr(context).error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final current = context.watch<LocaleProvider>().locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Language ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.language,
                      style: Theme.of(context).textTheme.titleMedium),
                  RadioListTile<String>(
                    value: 'ar',
                    groupValue: current,
                    onChanged: (v) => _setLanguage('ar'),
                    title: const Text('العربية'),
                  ),
                  RadioListTile<String>(
                    value: 'ckb',
                    groupValue: current,
                    onChanged: (v) => _setLanguage('ckb'),
                    title: const Text('کوردی (سۆرانی)'),
                  ),
                  RadioListTile<String>(
                    value: 'en',
                    groupValue: current,
                    onChanged: (v) => _setLanguage('en'),
                    title: const Text('English'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ---- Profile ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: t.fullName)),
                const SizedBox(height: 8),
                TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: t.phone)),
                if (widget.user.isLawyer) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: _bio,
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: t.lawyerProfile)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(t.save),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E)),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(t.signOut),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Icon(Icons.balance, color: MeezanTheme.gold, size: 28),
          ),
        ],
      ),
    );
  }
}
