import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Lawyer onboarding step: upload the Iraqi Lawyers Syndicate card
/// (هوية نقابة المحامين العراقيين) to Storage at verification/{uid}/...
/// The path is written to users/{uid}.syndicateDocPath and the account stays
/// 'pending' until an admin approves it from the web Admin Control Panel.
class VerificationScreen extends StatefulWidget {
  final AppUser user;
  const VerificationScreen({super.key, required this.user});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Uint8List? _bytes;
  String _fileName = '';
  bool _busy = false;

  Future<void> _pick() async {
    // withData: true -> bytes are available on BOTH Android and Web.
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (res == null || res.files.isEmpty || res.files.first.bytes == null) {
      return;
    }
    setState(() {
      _bytes = res.files.first.bytes;
      _fileName = res.files.first.name;
    });
  }

  String _contentType(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (_bytes == null) return;
    setState(() => _busy = true);
    try {
      final path =
          'verification/${widget.user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final (storagePath, _) = await StorageService.uploadBytes(
          path: path, bytes: _bytes!, contentType: _contentType(_fileName));
      await FirestoreService.updateUser(widget.user.uid, {
        'syndicateDocPath': storagePath,
        'status': 'pending',
        'rejectionReason': '',
      });
      // RoleGate's user stream picks up the change -> StatusScreen (pending).
    } catch (_) {
      if (mounted) showSnack(context, tr(context).error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.verificationTitle),
        actions: [
          IconButton(
              onPressed: AuthService.signOut,
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 72, color: MeezanTheme.gold),
                const SizedBox(height: 16),
                Text(t.verificationBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_fileName.isEmpty
                      ? t.uploadSyndicateCard
                      : '${t.fileSelected}: $_fileName'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_bytes == null || _busy) ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.submitForReview),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
