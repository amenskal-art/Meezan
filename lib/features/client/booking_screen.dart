import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/locale_provider.dart';
import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Consultation booking: pick an approved lawyer, a type
/// (video / phone / in-person), a date and a time. Below the form, the
/// client's upcoming and past appointments are listed live.
class BookingScreen extends StatefulWidget {
  final AppUser user;
  /// Optionally pre-selected lawyer (when arriving from the directory).
  final AppUser? preselectedLawyer;
  const BookingScreen({super.key, required this.user, this.preselectedLawyer});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  AppUser? _lawyer;
  String _type = 'video';
  DateTime? _date;
  TimeOfDay? _time;
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lawyer = widget.preselectedLawyer;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        initialDate: now);
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (t != null) setState(() => _time = t);
  }

  Future<void> _book() async {
    if (_lawyer == null || _date == null || _time == null) return;
    setState(() => _busy = true);
    try {
      final when = DateTime(_date!.year, _date!.month, _date!.day,
          _time!.hour, _time!.minute);
      await FirestoreService.createAppointment(Appointment(
        id: '',
        clientId: widget.user.uid,
        lawyerId: _lawyer!.uid,
        clientName: widget.user.name,
        lawyerName: _lawyer!.name,
        type: _type,
        status: 'scheduled',
        notes: _notes.text.trim(),
        whenMs: when.millisecondsSinceEpoch,
      ));
      if (mounted) {
        showSnack(context, tr(context).booked);
        setState(() {
          _date = null;
          _time = null;
          _notes.clear();
        });
      }
    } catch (_) {
      if (mounted) showSnack(context, tr(context).error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _typeIcon(String type) => switch (type) {
        'video' => Icons.videocam_outlined,
        'phone' => Icons.call_outlined,
        'deadline' => Icons.alarm,
        _ => Icons.location_on_outlined,
      };

  String _typeLabel(BuildContext c, String type) {
    final t = tr(c);
    return switch (type) {
      'video' => t.typeVideo,
      'phone' => t.typePhone,
      'deadline' => t.typeDeadline,
      _ => t.typeInPerson,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.bookConsultation,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                // --- Lawyer selector (approved lawyers only) ---
                StreamBuilder<List<AppUser>>(
                  stream: FirestoreService.approvedLawyers(),
                  builder: (context, snap) {
                    final lawyers = snap.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _lawyer?.uid,
                      decoration: InputDecoration(
                          labelText: t.chooseLawyer,
                          prefixIcon: const Icon(Icons.person_search)),
                      items: [
                        for (final l in lawyers)
                          DropdownMenuItem(
                            value: l.uid,
                            child: Text(
                                '${l.name} — ${Specializations.label(l.specialization, lang)}',
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        for (final l in lawyers) {
                          if (l.uid == v) {
                            _lawyer = l;
                            return;
                          }
                        }
                      }),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(t.consultationType),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'video',
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(t.typeVideo)),
                    ButtonSegment(
                        value: 'phone',
                        icon: const Icon(Icons.call_outlined),
                        label: Text(t.typePhone)),
                    ButtonSegment(
                        value: 'in_person',
                        icon: const Icon(Icons.location_on_outlined),
                        label: Text(t.typeInPerson)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(_date == null
                          ? t.pickDate
                          : fmtDate(_date!.millisecondsSinceEpoch)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(_time == null
                          ? t.pickTime
                          : _time!.format(context)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: t.notes),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: (_lawyer != null &&
                          _date != null &&
                          _time != null &&
                          !_busy)
                      ? _book
                      : null,
                  icon: const Icon(Icons.check),
                  label: Text(t.bookNow),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(t.myAppointments,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Appointment>>(
          stream:
              FirestoreService.appointmentsFor(widget.user.uid, asLawyer: false),
          builder: (context, snap) {
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return EmptyState(
                  icon: Icons.event_busy_outlined, text: t.myAppointments);
            }
            return Column(children: [
              for (final a in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          MeezanTheme.navy.withValues(alpha: 0.08),
                      child: Icon(_typeIcon(a.type),
                          color: MeezanTheme.navy, size: 20),
                    ),
                    title: Text(a.lawyerName.isEmpty ? '—' : a.lawyerName),
                    subtitle: Text(
                        '${_typeLabel(context, a.type)} · ${fmtDateTime(a.whenMs)}'),
                    trailing: StatusChip(a.status),
                  ),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
