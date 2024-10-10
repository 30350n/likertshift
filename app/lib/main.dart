import "package:flutter/material.dart";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:provider/provider.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/colors.dart";
import "package:likertshift/home.dart";
import "package:likertshift/location.dart";
import "package:likertshift/system_navigation_bar.dart";

void main() {
  runApp(const App());

  updateSystemNavigationBarTheme();
  WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
      updateSystemNavigationBarTheme;
}

class App extends StatelessWidget {
  const App({super.key});

  static final lightTheme = ThemeData.light(useMaterial3: true)
      .copyWith(extensions: [const AppColors.fromBrightness(Brightness.light)]);
  static final darkTheme = ThemeData.dark(useMaterial3: true)
      .copyWith(extensions: [const AppColors.fromBrightness(Brightness.dark)]);

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: lightTheme,
      dark: darkTheme,
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BluetoothModel()),
            ChangeNotifierProvider(create: (_) => LocationModel()),
          ],
          child: const Home(),
        ),
      ),
    );
  }
}
