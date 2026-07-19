import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/locale_provider.dart';
import '../../core/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';
import 'booking_screen.dart';

/// Searchable directory of VERIFIED (status == 'approved') lawyers only,
/// filterable by specialization and Iraqi governorate, plus a free-text name
/// filter applied client-side.
class DirectoryScreen extends StatefulWidget {
  final AppUser user;
  const DirectoryScreen({super.key, required this.user});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String? _spec;
  String? _gov;
  String _query = '';

  void _showProfile(AppUser lawyer, String lang) {
    final t = tr(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: MeezanTheme.navy,
                child: Icon(Icons.person, color: MeezanTheme.gold, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lawyer.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                        '${Specializations.label(lawyer.specialization, lang)} · ${Governorates.label(lawyer.governorate, lang)}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.blueGrey)),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: MeezanTheme.gold),
            ]),
            if (lawyer.bio.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(lawyer.bio),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.event),
              label: Text('${t.bookWith} ${lawyer.name}'),
              onPressed: () {
                Navigator.of(sheetCtx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(t.bookConsultation)),
                    body: BookingScreen(
                        user: widget.user, preselectedLawyer: lawyer),
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(children: [
          TextField(
            decoration: InputDecoration(
                hintText: t.search,
                prefixIcon: const Icon(Icons.search),
                isDense: true),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _spec,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: t.specialization, isDense: true),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(t.allSpecializations)),
                  for (final c in Specializations.codes)
                    DropdownMenuItem(
                        value: c, child: Text(Specializations.label(c, lang))),
                ],
                onChanged: (v) => setState(() => _spec = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _gov,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: t.governorate, isDense: true),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(t.allGovernorates)),
                  for (final c in Governorates.codes)
                    DropdownMenuItem(
                        value: c, child: Text(Governorates.label(c, lang))),
                ],
                onChanged: (v) => setState(() => _gov = v),
              ),
            ),
          ]),
        ]),
      ),
      Expanded(
        child: StreamBuilder<List<AppUser>>(
          stream: FirestoreService.approvedLawyers(
              specialization: _spec, governorate: _gov),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var lawyers = snap.data ?? [];
            if (_query.isNotEmpty) {
              lawyers = lawyers
                  .where((l) =>
                      l.name.toLowerCase().contains(_query.toLowerCase()))
                  .toList();
            }
            if (lawyers.isEmpty) {
              return EmptyState(
                  icon: Icons.person_search_outlined, text: t.lawyerDirectory);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: lawyers.length,
              itemBuilder: (context, i) {
                final l = lawyers[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _showProfile(l, lang),
                    leading: const CircleAvatar(
                      backgroundColor: MeezanTheme.navy,
                      child:
                          Icon(Icons.person, color: MeezanTheme.gold, size: 22),
                    ),
                    title: Row(children: [
                      Flexible(
                          child: Text(l.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 16, color: MeezanTheme.gold),
                    ]),
                    subtitle: Text(
                        '${Specializations.label(l.specialization, lang)} · ${Governorates.label(l.governorate, lang)}'),
                    trailing: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
