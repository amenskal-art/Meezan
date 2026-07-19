import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Interactive case tracking for clients: court, case number, status,
/// next hearing date and a milestone timeline with completion progress.
class CaseTrackingScreen extends StatelessWidget {
  final AppUser user;
  const CaseTrackingScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return StreamBuilder<List<LegalCase>>(
      stream: FirestoreService.casesFor(user.uid, asLawyer: false),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final cases = snap.data ?? [];
        if (cases.isEmpty) {
          return EmptyState(icon: Icons.folder_off_outlined, text: t.noCases);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cases.length,
          itemBuilder: (context, i) => _CaseCard(c: cases[i]),
        );
      },
    );
  }
}

class _CaseCard extends StatelessWidget {
  final LegalCase c;
  const _CaseCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final done = c.milestones.where((m) => m.done).length;
    final total = c.milestones.length;
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            StatusChip(c.status),
            if (c.caseNumber.isNotEmpty)
              Text('${t.caseNumber}: ${c.caseNumber}',
                  style: const TextStyle(fontSize: 12)),
          ]),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (c.court.isNotEmpty)
            _row(Icons.account_balance_outlined, '${t.court}: ${c.court}'),
          _row(Icons.event_outlined,
              '${t.nextHearing}: ${fmtDateTime(c.nextHearingMs)}'),
          if (total > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              Text(t.milestones,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$done / $total', style: const TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              color: MeezanTheme.gold,
              backgroundColor:
                  MeezanTheme.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            for (final m in c.milestones)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  m.done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: m.done ? const Color(0xFF2E7D32) : Colors.blueGrey,
                  size: 20,
                ),
                title: Text(m.title),
                trailing: Text(fmtDate(m.dateMs),
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
