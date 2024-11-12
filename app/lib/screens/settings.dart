import "package:flutter/material.dart";
import "package:flutter_translate/flutter_translate.dart";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:likertshift/forms.dart";

import "package:likertshift/system_navigation_bar.dart";
import "package:likertshift/util.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adaptiveTheme = AdaptiveTheme.of(context);
    final localization = LocalizedApp.of(context).delegate;
    final theme = Theme.of(context);

    return Scaffold(
      appBar:
          AppBar(leading: const Icon(Icons.settings), title: Text(translate("settings.title"))),
      body: SeperatedListView(
        padding: EdgeInsets.zero,
        spacing: 8,
        children: [
          ListTile(
            title: Text(translate("settings.language")),
            leading: const Icon(Icons.language),
            trailing: DropdownMenu<String>(
              initialSelection: localization.currentLocale.languageCode,
              dropdownMenuEntries: localization.supportedLocales
                  .map(
                    (locale) => DropdownMenuEntry(
                      value: locale.languageCode,
                      label: translate("settings.languages.${locale.languageCode}"),
                    ),
                  )
                  .toList(),
              onSelected: (language) async {
                if (language != null) {
                  await changeLocale(context, language);
                }
              },
            ),
          ),
          ListTile(
            title: Text(translate("settings.color_scheme")),
            leading: const Icon(Icons.format_paint),
            trailing: DropdownMenu<AdaptiveThemeMode>(
              initialSelection: adaptiveTheme.mode,
              dropdownMenuEntries: AdaptiveThemeMode.values
                  .map(
                    (mode) => DropdownMenuEntry(
                      value: mode,
                      label: translate("settings.color_schemes.${mode.name}"),
                    ),
                  )
                  .toList(),
              onSelected: (theme) {
                if (theme != null) {
                  adaptiveTheme.setThemeMode(theme);
                  updateSystemNavigationBarTheme();
                }
              },
            ),
          ),
          ListTile(
            title:
                Text(translate("settings.debug_forms"), style: theme.textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              child: Text(
                translate("forms.demographics.title"),
                style: theme.textTheme.titleMedium,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JsonForm("demographics", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              child: Text(translate("forms.bfi-10.title"), style: theme.textTheme.titleMedium),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JsonForm("bfi-10", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              child: Text(translate("forms.tlx.title"), style: theme.textTheme.titleMedium),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JsonForm("tlx", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              child: Text("UEQ+", style: theme.textTheme.titleMedium),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const JsonForm("ueq_01_attractiveness", prefix: "debug"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
