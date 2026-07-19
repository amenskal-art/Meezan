import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Secure document vault: clients upload files to Storage (vault/{uid}/...)
/// and can share individual documents with lawyers assigned to their cases.
/// Sharing = adding the lawyer uid to the doc's `sharedWith` array, which the
/// Firestore rules honor for read access, and the lawyer sees it inside the
/// case detail via docsSharedWith().
class VaultScreen extends StatefulWidget {
  final AppUser user;
  const VaultScreen({super.key, required this.user});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _uploading = false;

  String _contentType(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.doc') || n.endsWith('.docx')) return 'application/msword';
    return 'application/octet-stream';
  }

  Future<void> _upload() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null || res.files.isEmpty || res.files.first.bytes == null) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final f = res.files.first;
      final path =
          'vault/${widget.user.uid}/${DateTime.now().millisecondsSinceEpoch}_${f.name}';
      final (storagePath, url) = await StorageService.uploadBytes(
          path: path, bytes: f.bytes!, contentType: _contentType(f.name));
      await FirestoreService.createDoc(VaultDoc(
        id: '',
        ownerId: widget.user.uid,
        name: f.name,
        storagePath: storagePath,
        url: url,
        uploadedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    } catch (_) {
      if (mounted) showSnack(context, tr(context).error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Lists the lawyers attached to the client's cases as share targets.
  Future<void> _share(VaultDoc doc) async {
    final t = tr(context);
    final cases = await FirestoreService.casesFor(widget.user.uid,
            asLawyer: false)
        .first;
    // Unique lawyerId -> display name (from the case doc, no extra reads).
    final lawyers = <String, String>{};
    for (final c in cases) {
      if (c.lawyerId.isNotEmpty) {
        lawyers.putIfAbsent(c.lawyerId, () => c.title);
      }
    }
    if (!mounted) return;
    if (lawyers.isEmpty) {
      showSnack(context, t.noLawyersToShare);
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(t.shareWithLawyer,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in lawyers.entries)
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: Text(e.value), // case title as context
              trailing: doc.sharedWith.contains(e.key)
                  ? const Icon(Icons.check, color: MeezanTheme.gold)
                  : const Icon(Icons.share_outlined),
              onTap: () async {
                await FirestoreService.shareDoc(doc.id, e.key);
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file),
        label: Text(t.uploadDocument),
      ),
      body: StreamBuilder<List<VaultDoc>>(
        stream: FirestoreService.docsOwned(widget.user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = List<VaultDoc>.of(snap.data ?? [])
            ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          if (docs.isEmpty) {
            return EmptyState(
                icon: Icons.folder_open_outlined, text: t.noDocuments);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: MeezanTheme.paper,
                    child: Icon(Icons.description_outlined,
                        color: MeezanTheme.navy),
                  ),
                  title: Text(d.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Row(children: [
                    Text(fmtDate(d.uploadedAt),
                        style: const TextStyle(fontSize: 12)),
                    if (d.sharedWith.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.people_alt,
                          size: 14, color: MeezanTheme.gold),
                      const SizedBox(width: 3),
                      Text(t.sharedBadge,
                          style: const TextStyle(
                              fontSize: 12, color: MeezanTheme.gold)),
                    ],
                  ]),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'share':
                          await _share(d);
                        case 'open':
                          // Opens the secure download URL in the browser /
                          // system viewer (new tab on web).
                          await launchUrl(Uri.parse(d.url),
                              mode: LaunchMode.externalApplication);
                        case 'delete':
                          await FirestoreService.deleteDoc(d.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'share', child: Text(t.shareWithLawyer)),
                      PopupMenuItem(value: 'open', child: Text(t.openFile)),
                      PopupMenuItem(
                          value: 'delete', child: Text(t.deleteDocument)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
