import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:flutter_translate/flutter_translate.dart";
import "package:provider/provider.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/colors.dart";
import "package:likertshift/home.dart";
import "package:likertshift/location.dart";
import "package:likertshift/recording.dart";
import "package:likertshift/system_navigation_bar.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bluetoothModel = BluetoothModel();
  final locationModel = await LocationModel.create();

  final localizationDelegate = await LocalizationDelegate.create(
    fallbackLocale: "en",
    supportedLocales: ["en", "de"],
    basePath: "assets/locales/",
  );

  runApp(
    LocalizedApp(
      localizationDelegate,
      App(
        bluetoothModel: bluetoothModel,
        locationModel: locationModel,
        recordingModel: await RecordingModel.create(bluetoothModel, locationModel),
      ),
    ),
  );

  unawaited(updateSystemNavigationBarTheme());
  WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
      updateSystemNavigationBarTheme;
}

class App extends StatelessWidget {
  final BluetoothModel bluetoothModel;
  final RecordingModel recordingModel;
  final LocationModel locationModel;

  const App({
    super.key,
    required this.bluetoothModel,
    required this.locationModel,
    required this.recordingModel,
  });

  static final lightTheme = ThemeData.light(useMaterial3: true)
      .copyWith(extensions: [AppColors.fromBrightness(Brightness.light)]);
  static final darkTheme = ThemeData.dark(useMaterial3: true)
      .copyWith(extensions: [AppColors.fromBrightness(Brightness.dark)]);

  @override
  Widget build(BuildContext context) {
    final localizationDelegate = LocalizedApp.of(context).delegate;

    return AdaptiveTheme(
      light: lightTheme,
      dark: darkTheme,
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => LocalizationProvider(
        state: LocalizationProvider.of(context).state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          localizationsDelegates: [
            localizationDelegate,
            ...GlobalMaterialLocalizations.delegates,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: localizationDelegate.supportedLocales,
          locale: localizationDelegate.currentLocale,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => bluetoothModel),
              ChangeNotifierProvider(create: (_) => locationModel),
              ChangeNotifierProvider(create: (_) => recordingModel),
            ],
            // ignore: prefer_const_constructors
            child: Home(),
          ),
        ),
      ),
    );
  }
}
