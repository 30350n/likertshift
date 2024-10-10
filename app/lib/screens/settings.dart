import "package:flutter/material.dart";

import "package:adaptive_theme/adaptive_theme.dart";

import "package:likertshift/system_navigation_bar.dart";
import "package:likertshift/util.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adaptiveTheme = AdaptiveTheme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const Icon(Icons.settings), title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Theme"),
            leading: const Icon(Icons.format_paint),
            trailing: DropdownMenu<AdaptiveThemeMode>(
              initialSelection: adaptiveTheme.mode,
              dropdownMenuEntries: AdaptiveThemeMode.values
                  .map((mode) => DropdownMenuEntry(value: mode, label: mode.name.capitalize()))
                  .toList(),
              onSelected: (theme) {
                if (theme != null) {
                  adaptiveTheme.setThemeMode(theme);
                  updateSystemNavigationBarTheme();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
