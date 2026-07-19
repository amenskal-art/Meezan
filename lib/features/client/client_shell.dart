import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/ui_helpers.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import 'booking_screen.dart';
import 'case_tracking_screen.dart';
import 'directory_screen.dart';
import 'vault_screen.dart';

/// Client (B2C) dashboard shell — the layout mirrors the MEEZAN mockup:
/// navy header, gold accents, bottom navigation with the 5 core client tools.
class ClientShell extends StatefulWidget {
  final AppUser user;
  const ClientShell({super.key, required this.user});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final pages = [
      CaseTrackingScreen(user: widget.user),
      BookingScreen(user: widget.user),
      DirectoryScreen(user: widget.user),
      VaultScreen(user: widget.user),
      ChatScreen(user: widget.user),
    ];
    final titles = [t.myCases, t.bookConsultation, t.lawyerDirectory,
        t.documentsVault, t.aiAssistant];
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
              icon: const Icon(Icons.folder_open_outlined),
              selectedIcon: const Icon(Icons.folder_open),
              label: t.navHome),
          NavigationDestination(
              icon: const Icon(Icons.event_outlined),
              selectedIcon: const Icon(Icons.event),
              label: t.navBooking),
          NavigationDestination(
              icon: const Icon(Icons.people_alt_outlined),
              selectedIcon: const Icon(Icons.people_alt),
              label: t.navLawyers),
          NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description),
              label: t.navVault),
          NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: t.navAi),
        ],
      ),
    );
  }
}
