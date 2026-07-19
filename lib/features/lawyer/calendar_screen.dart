import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Smart calendar for lawyers. It merges three event sources onto one grid:
///   1. consultation appointments booked by clients
///   2. court hearing dates set on cases (محاكم البداءة، الاستئناف، التمييز...)
///   3. statutory deadlines the lawyer adds manually — with a helper banner
///      reminding the common windows of the Iraqi Civil Procedure Code
///      (قانون المرافعات المدنية رقم 83 لسنة 1969).
class CalendarScreen extends StatefulWidget {
  final AppUser user;
  const CalendarScreen({super.key, required this.user});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarEvent {
  final String title;
  final String type; // appointment type / 'hearing' / 'deadline'
  final int whenMs;
  const _CalendarEvent(this.title, this.type, this.whenMs);
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  DateTime _dayKey(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.utc(d.year, d.month, d.day);
  }

  Map<DateTime, List<_CalendarEvent>> _buildEvents(
      List<Appointment> appts, List<LegalCase> cases) {
    final map = <DateTime, List<_CalendarEvent>>{};
    void add(_CalendarEvent e) {
      if (e.whenMs == 0) return;
      map.putIfAbsent(_dayKey(e.whenMs), () => []).add(e);
    }

    for (final a in appts) {
      add(_CalendarEvent(
          a.clientName.isEmpty ? a.notes : a.clientName, a.type, a.whenMs));
    }
    for (final c in cases) {
      add(_CalendarEvent(c.title, 'hearing', c.nextHearingMs));
    }
    return map;
  }

  Future<void> _addDeadline() async {
    final t = tr(context);
    final title = TextEditingController();
    final base = _selected ?? DateTime.now();
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.addDeadline),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              decoration: InputDecoration(labelText: t.deadlineTitle)),
          const SizedBox(height: 8),
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(fmtDate(base.millisecondsSinceEpoch))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(t.cancel)),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              // Deadlines are stored as appointments of type 'deadline' where
              // the lawyer is both parties — keeps one collection + rules.
              await FirestoreService.createAppointment(Appointment(
                id: '',
                clientId: widget.user.uid,
                lawyerId: widget.user.uid,
                lawyerName: widget.user.name,
                type: 'deadline',
                status: 'scheduled',
                notes: title.text.trim(),
                whenMs: DateTime(base.year, base.month, base.day, 9)
                    .millisecondsSinceEpoch,
              ));
              if (dCtx.mounted) Navigator.of(dCtx).pop();
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
        'video' => Icons.videocam_outlined,
        'phone' => Icons.call_outlined,
        'in_person' => Icons.location_on_outlined,
        'hearing' => Icons.account_balance_outlined,
        _ => Icons.alarm,
      };

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDeadline,
        icon: const Icon(Icons.alarm_add),
        label: Text(t.addDeadline),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream:
            FirestoreService.appointmentsFor(widget.user.uid, asLawyer: true),
        builder: (context, apptSnap) {
          return StreamBuilder<List<LegalCase>>(
            stream: FirestoreService.casesFor(widget.user.uid, asLawyer: true),
            builder: (context, caseSnap) {
              final events =
                  _buildEvents(apptSnap.data ?? [], caseSnap.data ?? []);
              final selectedEvents = _selected == null
                  ? const <_CalendarEvent>[]
                  : (events[_dayKey(
                          _selected!.millisecondsSinceEpoch)] ??
                      const <_CalendarEvent>[]);
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
                children: [
                  // --- Statutory reminder banner (Civil Procedure Code) ---
                  Card(
                    color: MeezanTheme.gold.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.gavel, color: MeezanTheme.gold),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(t.statutoryHint,
                                style: const TextStyle(fontSize: 12))),
                      ]),
                    ),
                  ),
                  TableCalendar<_CalendarEvent>(
                    firstDay: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 730)),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(d, _selected),
                    eventLoader: (d) =>
                        events[DateTime.utc(d.year, d.month, d.day)] ??
                        const [],
                    onDaySelected: (sel, foc) =>
                        setState(() {
                      _selected = sel;
                      _focused = foc;
                    }),
                    onPageChanged: (foc) => _focused = foc,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                          color: MeezanTheme.navy, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: MeezanTheme.gold.withValues(alpha: 0.5),
                          shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(
                          color: MeezanTheme.gold, shape: BoxShape.circle),
                    ),
                    headerStyle: const HeaderStyle(
                        formatButtonVisible: false, titleCentered: true),
                  ),
                  const SizedBox(height: 8),
                  for (final e in selectedEvents)
                    Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(_icon(e.type), color: MeezanTheme.navy),
                        title: Text(e.title.isEmpty ? '—' : e.title),
                        subtitle: Text(fmtDateTime(e.whenMs)),
                        trailing: e.type == 'deadline'
                            ? StatusChip('pending')
                            : null,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
