import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/locale_provider.dart';
import '../../core/models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Web-based Admin Control Panel (spec requirement). The same Flutter web
/// build serves it: any signed-in account holding the `admin` custom claim
/// (granted via the grant-admin GitHub workflow) is routed here by RoleGate.
///
/// Three tabs stream lawyers by status. For pending applications the admin
/// can open the uploaded syndicate card straight from Storage, then Approve
/// (lawyer appears in the public directory + approval email is queued by the
/// onLawyerStatusChange Cloud Function) or Reject with a reason (stored on
/// the user doc AND emailed to the applicant).
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.adminPanel),
          actions: [
            IconButton(
                onPressed: AuthService.signOut,
                icon: const Icon(Icons.logout)),
          ],
          bottom: TabBar(
            indicatorColor: MeezanTheme.gold,
            labelColor: MeezanTheme.gold,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: t.pendingApplications),
              Tab(text: t.tabApproved),
              Tab(text: t.tabRejected),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _LawyerList(status: 'pending'),
          _LawyerList(status: 'approved'),
          _LawyerList(status: 'rejected'),
        ]),
      ),
    );
  }
}

class _LawyerList extends StatelessWidget {
  final String status;
  const _LawyerList({required this.status});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return StreamBuilder<List<AppUser>>(
      stream: FirestoreService.lawyersByStatus(status),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final lawyers = snap.data ?? [];
        if (lawyers.isEmpty) {
          return EmptyState(icon: Icons.inbox_outlined, text: t.noPending);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lawyers.length,
          itemBuilder: (context, i) => _ApplicationCard(lawyer: lawyers[i]),
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AppUser lawyer;
  const _ApplicationCard({required this.lawyer});

  Future<void> _viewDocument(BuildContext context) async {
    if (lawyer.syndicateDocPath.isEmpty) return;
    try {
      final url = await StorageService.downloadUrl(lawyer.syndicateDocPath);
      if (!context.mounted) return;
      final isPdf = lawyer.syndicateDocPath.toLowerCase().endsWith('.pdf');
      await showDialog<void>(
        context: context,
        builder: (dCtx) => Dialog(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                      child: Text(lawyer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700))),
                  IconButton(
                      onPressed: () => launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new)),
                  IconButton(
                      onPressed: () => Navigator.of(dCtx).pop(),
                      icon: const Icon(Icons.close)),
                ]),
              ),
              Flexible(
                child: isPdf
                    // PDFs open in a new tab; show the link fallback inline.
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(url),
                      )
                    : InteractiveViewer(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: SelectableText(url),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) showSnack(context, tr(context).error);
    }
  }

  Future<void> _approve(BuildContext context) async {
    final t = tr(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        content: Text(t.confirmApprove),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: Text(t.approve)),
        ],
      ),
    );
    if (ok == true) {
      // The onLawyerStatusChange Cloud Function queues the approval email.
      await FirestoreService.updateUser(
          lawyer.uid, {'status': 'approved', 'rejectionReason': ''});
    }
  }

  Future<void> _reject(BuildContext context) async {
    final t = tr(context);
    final reason = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.reject),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: InputDecoration(hintText: t.rejectReasonHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E)),
            onPressed: () async {
              // The Cloud Function emails this reason to the applicant.
              await FirestoreService.updateUser(lawyer.uid, {
                'status': 'rejected',
                'rejectionReason': reason.text.trim(),
              });
              if (dCtx.mounted) Navigator.of(dCtx).pop();
            },
            child: Text(t.reject),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const CircleAvatar(
              backgroundColor: MeezanTheme.navy,
              child: Icon(Icons.person, color: MeezanTheme.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lawyer.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                  Text(lawyer.email,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueGrey)),
                  Text(
                      '${Specializations.label(lawyer.specialization, lang)} · ${Governorates.label(lawyer.governorate, lang)}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            StatusChip(lawyer.status),
          ]),
          if (lawyer.status == 'rejected' &&
              lawyer.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${t.rejectionReasonLabel}: ${lawyer.rejectionReason}',
                style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            TextButton.icon(
              onPressed: lawyer.syndicateDocPath.isEmpty
                  ? null
                  : () => _viewDocument(context),
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: Text(t.viewDocument),
            ),
            const Spacer(),
            if (lawyer.status != 'approved')
              FilledButton(
                onPressed: () => _approve(context),
                child: Text(t.approve),
              ),
            if (lawyer.status == 'pending') ...[
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E)),
                onPressed: () => _reject(context),
                child: Text(t.reject),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
