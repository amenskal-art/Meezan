import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Iraqi legal library: an offline quick-reference of the major Iraqi codes
/// bundled as assets/legal_library.json. Each code has a list of key articles
/// with Arabic summaries; the search box filters across codes and articles.
class LibraryScreen extends StatefulWidget {
  final AppUser user;
  const LibraryScreen({super.key, required this.user});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> _codes = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/legal_library.json');
    setState(() => _codes = (jsonDecode(raw) as Map)['codes'] as List);
  }

  bool _matches(Map code) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if ((code['name'] as String).toLowerCase().contains(q) ||
        (code['name_en'] as String? ?? '').toLowerCase().contains(q)) {
      return true;
    }
    for (final a in (code['articles'] as List)) {
      if ((a['title'] as String).toLowerCase().contains(q) ||
          (a['summary'] as String).toLowerCase().contains(q)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final visible = _codes.where((c) => _matches(c as Map)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          decoration: InputDecoration(
              hintText: t.searchLaws,
              prefixIcon: const Icon(Icons.search),
              isDense: true),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      Expanded(
        child: _codes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final code = visible[i] as Map;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: const CircleAvatar(
                        backgroundColor: MeezanTheme.navy,
                        child: Icon(Icons.menu_book,
                            color: MeezanTheme.gold, size: 20),
                      ),
                      title: Text(code['name'] as String,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(code['number'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.blueGrey)),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        for (final a in (code['articles'] as List))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Text(a['title'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: MeezanTheme.navy)),
                                const SizedBox(height: 3),
                                Text(a['summary'] as String,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
