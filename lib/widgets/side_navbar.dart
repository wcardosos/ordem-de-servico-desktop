import 'package:flutter/material.dart';

import 'app_module.dart';

class SideNavbar extends StatelessWidget {
  const SideNavbar({
    super.key,
    required this.modules,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSignOut,
  });

  static const Key signOutButtonKey = Key('sideNavbarSignOutButton');

  static Key itemKey(String label) => ValueKey<String>('sideNavbarItem-$label');

  final List<AppModule> modules;

  final int selectedIndex;

  final ValueChanged<int> onSelected;

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Ordem de Serviço',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: modules.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 4),
                itemBuilder: (BuildContext context, int index) {
                  final AppModule module = modules[index];
                  final bool selected = index == selectedIndex;
                  return ListTile(
                    key: itemKey(module.label),
                    selected: selected,
                    selectedTileColor: colors.secondaryContainer,
                    selectedColor: colors.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(module.icon),
                    title: Text(module.label),
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
            ListTile(
              key: signOutButtonKey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
