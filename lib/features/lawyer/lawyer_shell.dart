import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/ui_helpers.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import 'billing_screen.dart';
import 'calendar_screen.dart';
import 'case_management_screen.dart';
import 'library_screen.dart';

/// Lawyer (B2B practice management) dashboard shell.
/// Only reachable when status == 'approved' (enforced by RoleGate + rules).
class LawyerShell extends StatefulWidget {
  final AppUser user;
  const LawyerShell({super.key, required this.user});

  @override
  State<LawyerShell> createState() => _LawyerShellState();
}

class _LawyerShellState extends State<LawyerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final pages = [
      CaseManagementScreen(user: widget.user),
      CalendarScreen(user: widget.user),
      BillingScreen(user: widget.user),
      LibraryScreen(user: widget.user),
      ChatScreen(user: widget.user),
    ];
    final titles = [t.caseManagement, t.smartCalendar, t.billing,
        t.legalLibrary, t.aiCoCounsel];
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0
            ? t.welcomeUser(widget.user.name.split(' ').first)
            : titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsScreen(user: widget.user))),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.work_outline),
              selectedIcon: const Icon(Icons.work),
              label: t.navCases),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: t.navCalendar),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: t.navBilling),
          NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: t.navLibrary),
          NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: t.navAi),
        ],
      ),
    );
  }
}
