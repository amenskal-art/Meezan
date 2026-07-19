import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Lawyer case management:
///  - create a case by looking up the client's registered email
///  - milestone timeline (add / mark done)
///  - set the next hearing date
///  - view documents the client shared from their vault
class CaseManagementScreen extends StatelessWidget {
  final AppUser user;
  const CaseManagementScreen({super.key, required this.user});

  Future<void> _newCase(BuildContext context) async {
    final t = tr(context);
    final email = TextEditingController();
    final title = TextEditingController();
    final caseNo = TextEditingController();
    final court = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.newCase),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: t.clientEmail)),
            const SizedBox(height: 8),
            TextField(
                controller: title,
                decoration: InputDecoration(labelText: t.caseTitle)),
            const SizedBox(height: 8),
            TextField(
                controller: caseNo,
                decoration: InputDecoration(labelText: t.caseNumber)),
            const SizedBox(height: 8),
            TextField(
                controller: court,
                decoration: InputDecoration(labelText: t.court)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(t.cancel)),
          FilledButton(
            onPressed: () async {
              final client =
                  await FirestoreService.findClientByEmail(email.text);
              if (client == null) {
                if (dCtx.mounted) showSnack(dCtx, t.clientNotFound);
                return;
              }
              await FirestoreService.createCase(LegalCase(
                id: '',
                clientId: client.uid,
                lawyerId: user.uid,
                clientName: client.name,
                title: title.text.trim(),
                caseNumber: caseNo.text.trim(),
                court: court.text.trim(),
                status: 'active',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ));
              if (dCtx.mounted) Navigator.of(dCtx).pop();
            },
            child: Text(t.save),
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
        onPressed: () => _newCase(context),
        icon: const Icon(Icons.add),
        label: Text(t.newCase),
      ),
      body: StreamBuilder<List<LegalCase>>(
        stream: FirestoreService.casesFor(user.uid, asLawyer: true),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cases = snap.data ?? [];
          if (cases.isEmpty) {
            return EmptyState(icon: Icons.work_off_outlined, text: t.noCases);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: cases.length,
            itemBuilder: (context, i) => _LawyerCaseCard(c: cases[i]),
          );
        },
      ),
    );
  }
}

class _LawyerCaseCard extends StatelessWidget {
  final LegalCase c;
  const _LawyerCaseCard({required this.c});

  Future<void> _addMilestone(BuildContext context) async {
    final t = tr(context);
    final title = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.addMilestone),
        content: TextField(
            controller: title,
            decoration: InputDecoration(labelText: t.milestoneTitle)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(t.cancel)),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              final updated = [
                ...c.milestones,
                Milestone(
                    title: title.text.trim(),
                    dateMs: DateTime.now().millisecondsSinceEpoch),
              ];
              await FirestoreService.updateCase(c.id, {
                'milestones': updated.map((m) => m.toMap()).toList(),
              });
              if (dCtx.mounted) Navigator.of(dCtx).pop();
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMilestone(int index) async {
    final updated = [
      for (var i = 0; i < c.milestones.length; i++)
        i == index
            ? Milestone(
                title: c.milestones[i].title,
                dateMs: c.milestones[i].dateMs,
                done: !c.milestones[i].done)
            : c.milestones[i],
    ];
    await FirestoreService.updateCase(
        c.id, {'milestones': updated.map((m) => m.toMap()).toList()});
  }

  Future<void> _setHearing(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        firstDate: now,
        lastDate: now.add(const Duration(days: 730)),
        initialDate: now);
    if (d == null || !context.mounted) return;
    final tm = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (tm == null) return;
    final when = DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
    await FirestoreService.updateCase(
        c.id, {'nextHearingMs': when.millisecondsSinceEpoch});
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        leading: const CircleAvatar(
          backgroundColor: MeezanTheme.navy,
          child: Icon(Icons.gavel, color: MeezanTheme.gold, size: 20),
        ),
        title: Text(c.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(c.clientName,
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(spacing: 8, runSpacing: 6, children: [
            StatusChip(c.status),
            if (c.caseNumber.isNotEmpty)
              Chip(
                  label: Text('${t.caseNumber}: ${c.caseNumber}',
                      style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact),
            if (c.court.isNotEmpty)
              Chip(
                  label: Text(c.court, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact),
          ]),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: MeezanTheme.gold),
            title: Text('${t.nextHearing}: ${fmtDateTime(c.nextHearingMs)}'),
            trailing: TextButton(
                onPressed: () => _setHearing(context),
                child: Text(t.setNextHearing)),
          ),
          const Divider(),
          Row(children: [
            Text(t.milestones,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
                onPressed: () => _addMilestone(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.addMilestone)),
          ]),
          for (var i = 0; i < c.milestones.length; i++)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: c.milestones[i].done,
              onChanged: (_) => _toggleMilestone(i),
              title: Text(c.milestones[i].title),
              subtitle: Text(fmtDate(c.milestones[i].dateMs),
                  style: const TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const Divider(),
          // --- Documents the client shared with this lawyer for this case ---
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(t.clientSharedDocs,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          StreamBuilder<List<VaultDoc>>(
            stream: FirestoreService.docsSharedWith(c.lawyerId),
            builder: (context, snap) {
              final docs = (snap.data ?? [])
                  .where((d) => d.ownerId == c.clientId)
                  .toList();
              if (docs.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(8), child: Text('—'));
              }
              return Column(children: [
                for (final d in docs)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(d.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      onPressed: () => launchUrl(Uri.parse(d.url),
                          mode: LaunchMode.externalApplication),
                    ),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}
