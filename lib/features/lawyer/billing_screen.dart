import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Billing & invoicing in Iraqi Dinar (IQD): issue invoices against a client
/// picked from the lawyer's cases, log installment (retainer) payments, and
/// auto-track unpaid / partial / paid state from the installment total.
class BillingScreen extends StatelessWidget {
  final AppUser user;
  const BillingScreen({super.key, required this.user});

  Future<void> _newInvoice(BuildContext context) async {
    final t = tr(context);
    final cases =
        await FirestoreService.casesFor(user.uid, asLawyer: true).first;
    if (!context.mounted) return;
    if (cases.isEmpty) {
      showSnack(context, t.noCases);
      return;
    }
    LegalCase selected = cases.first;
    final amount = TextEditingController();
    DateTime due = DateTime.now().add(const Duration(days: 30));
    await showDialog<void>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setD) => AlertDialog(
          title: Text(t.newInvoice),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: selected.id,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.caseTitle),
                items: [
                  for (final c in cases)
                    DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.title} — ${c.clientName}',
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setD(() =>
                    selected = cases.firstWhere((c) => c.id == v)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                    labelText: t.amountIqd, suffixText: 'د.ع'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                    '${t.dueDate}: ${fmtDate(due.millisecondsSinceEpoch)}'),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: dCtx,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 730)),
                      initialDate: due);
                  if (d != null) setD(() => due = d);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dCtx).pop(),
                child: Text(t.cancel)),
            FilledButton(
              onPressed: () async {
                final v = int.tryParse(amount.text.trim());
                if (v == null || v <= 0) return;
                await FirestoreService.createInvoice(InvoiceModel(
                  id: '',
                  lawyerId: user.uid,
                  clientId: selected.clientId,
                  clientName: selected.clientName,
                  caseId: selected.id,
                  status: 'unpaid',
                  amountIqd: v,
                  dueMs: due.millisecondsSinceEpoch,
                  issuedMs: DateTime.now().millisecondsSinceEpoch,
                ));
                if (dCtx.mounted) Navigator.of(dCtx).pop();
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInstallment(BuildContext context, InvoiceModel inv) async {
    final t = tr(context);
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.addInstallment),
        content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          decoration:
              InputDecoration(labelText: t.amountIqd, suffixText: 'د.ع'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(t.cancel)),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(amount.text.trim());
              if (v == null || v <= 0) return;
              final installments = [
                ...inv.installments,
                Installment(
                    amountIqd: v,
                    dateMs: DateTime.now().millisecondsSinceEpoch),
              ];
              final paid =
                  installments.fold(0, (s, i) => s + i.amountIqd);
              await FirestoreService.updateInvoice(inv.id, {
                'installments':
                    installments.map((i) => i.toMap()).toList(),
                'status': paid >= inv.amountIqd ? 'paid' : 'partial',
              });
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
        onPressed: () => _newInvoice(context),
        icon: const Icon(Icons.receipt_long),
        label: Text(t.newInvoice),
      ),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: FirestoreService.invoicesFor(user.uid, asLawyer: true),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoices = snap.data ?? [];
          if (invoices.isEmpty) {
            return EmptyState(
                icon: Icons.receipt_long_outlined, text: t.billing);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: invoices.length,
            itemBuilder: (context, i) {
              final inv = invoices[i];
              final paid = inv.paidIqd;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv.clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text('${t.dueDate}: ${fmtDate(inv.dueMs)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey)),
                            ],
                          ),
                        ),
                        StatusChip(inv.status),
                      ]),
                      const SizedBox(height: 10),
                      Text(formatIqd(inv.amountIqd),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: MeezanTheme.navy)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: inv.amountIqd == 0
                            ? 0
                            : (paid / inv.amountIqd).clamp(0, 1).toDouble(),
                        color: MeezanTheme.gold,
                        backgroundColor:
                            MeezanTheme.navy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 4),
                      Text(t.paidOf(formatIqd(paid), formatIqd(inv.amountIqd)),
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(children: [
                        TextButton.icon(
                          onPressed: inv.status == 'paid'
                              ? null
                              : () => _addInstallment(context, inv),
                          icon: const Icon(Icons.add_card, size: 18),
                          label: Text(t.addInstallment),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: inv.status == 'paid'
                              ? null
                              : () => FirestoreService.updateInvoice(
                                  inv.id, {'status': 'paid'}),
                          child: Text(t.markPaid),
                        ),
                      ]),
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
