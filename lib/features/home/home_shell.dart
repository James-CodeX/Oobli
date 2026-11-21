import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../ui/widgets/bottom_nav.dart';

/// Bottom-tab shell: Oobli Says · Plans · Goals · Wrapped.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const items = [
    NavItem(label: 'Oobli Says', icon: Icons.auto_awesome_rounded),
    NavItem(label: 'Plans', icon: Icons.event_note_rounded),
    NavItem(label: 'Goals', icon: Icons.track_changes_rounded),
    NavItem(label: 'Wrapped', icon: Icons.inventory_2_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: OobliBottomNav(
        items: items,
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
