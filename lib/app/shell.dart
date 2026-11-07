import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../features/add_entry/add_entry_sheet.dart';

/// Bottom nav shell: Home · Log · Plan · Accounts, with the floating + button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    NavItem(LucideIcons.house, 'Home'),
    NavItem(LucideIcons.calendarCheck, 'Log'),
    NavItem(LucideIcons.listChecks, 'Plan'),
    NavItem(LucideIcons.wallet, 'Accounts'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: shell,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Semantics(
            label: 'Add entry',
            button: true,
            child: FloatingActionButton(
              heroTag: 'add',
              tooltip: 'Add expense, income or transfer',
              onPressed: () => showAddEntrySheet(context),
              child: const Icon(LucideIcons.plus, size: 26),
            ),
          ),
        ),
        bottomNavigationBar: PillNavBar(
          items: _items,
          selected: shell.currentIndex,
          onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}
