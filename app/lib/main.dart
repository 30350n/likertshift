import "dart:async";

import "package:flutter/material.dart";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:provider/provider.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/colors.dart";
import "package:likertshift/demographics.dart";
import "package:likertshift/home.dart";
import "package:likertshift/location.dart";
import "package:likertshift/recording.dart";
import "package:likertshift/system_navigation_bar.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bluetoothModel = BluetoothModel();
  final locationModel = await LocationModel.create();

  runApp(
    App(
      bluetoothModel: bluetoothModel,
      demographicsModel: await DemographicsModel.create(),
      locationModel: locationModel,
      recordingModel: await RecordingModel.create(bluetoothModel, locationModel),
    ),
  );

  unawaited(updateSystemNavigationBarTheme());
  WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
      updateSystemNavigationBarTheme;
}

class App extends StatelessWidget {
  final BluetoothModel bluetoothModel;
  final DemographicsModel demographicsModel;
  final RecordingModel recordingModel;
  final LocationModel locationModel;

  const App({
    super.key,
    required this.bluetoothModel,
    required this.demographicsModel,
    required this.locationModel,
    required this.recordingModel,
  });

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
            ChangeNotifierProvider(create: (_) => bluetoothModel),
            ChangeNotifierProvider(create: (_) => demographicsModel),
            ChangeNotifierProvider(create: (_) => locationModel),
            ChangeNotifierProvider(create: (_) => recordingModel),
          ],
          child: const Home(),
        ),
      ),
    );
  }
}
