import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'theme.dart';

/// Shorthand accessor used across every screen.
AppLocalizations tr(BuildContext context) => AppLocalizations.of(context);

String fmtDate(int ms) {
  if (ms == 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

String fmtDateTime(int ms) {
  if (ms == 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${fmtDate(ms)}  $h:$m';
}

/// Localized status label + colored chip.
String statusLabel(BuildContext c, String status) {
  final t = tr(c);
  switch (status) {
    case 'pending':
      return t.statusPending;
    case 'approved':
      return t.statusApproved;
    case 'rejected':
      return t.statusRejected;
    case 'active':
      return t.statusActive;
    case 'closed':
      return t.statusClosed;
    case 'scheduled':
      return t.statusScheduled;
    case 'completed':
      return t.statusCompleted;
    case 'cancelled':
      return t.statusCancelled;
    case 'paid':
      return t.invoiceStatusPaid;
    case 'partial':
      return t.invoiceStatusPartial;
    case 'unpaid':
      return t.invoiceStatusUnpaid;
  }
  return status;
}

Color statusColor(String status) {
  switch (status) {
    case 'approved':
    case 'active':
    case 'paid':
    case 'completed':
      return const Color(0xFF2E7D32);
    case 'pending':
    case 'scheduled':
    case 'partial':
      return MeezanTheme.gold;
    case 'rejected':
    case 'cancelled':
    case 'unpaid':
      return const Color(0xFFB3261E);
    default:
      return Colors.blueGrey;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(statusLabel(context, status),
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: Colors.blueGrey.shade200),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade400)),
          ]),
        ),
      );
}
