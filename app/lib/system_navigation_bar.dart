import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "package:adaptive_theme/adaptive_theme.dart";

import "package:likertshift/main.dart";

Future<void> updateSystemNavigationBarTheme() async {
  ThemeData theme;
  switch (await AdaptiveTheme.getThemeMode()) {
    case AdaptiveThemeMode.system || null:
      if (WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light) {
        continue light;
      } else {
        continue dark;
      }

    light:
    case AdaptiveThemeMode.light:
      theme = App.lightTheme;

    dark:
    case AdaptiveThemeMode.dark:
      theme = App.darkTheme;
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness:
          theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
    ),
  );
}
