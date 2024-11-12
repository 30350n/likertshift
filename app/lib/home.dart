import "package:flutter/material.dart";
import "package:flutter_translate/flutter_translate.dart";

import "package:flutter_blue_plus/flutter_blue_plus.dart";
import "package:likertshift/forms.dart";
import "package:provider/provider.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/recording.dart";
import "package:likertshift/screens/devices.dart";
import "package:likertshift/screens/map.dart";
import "package:likertshift/screens/routes.dart";
import "package:likertshift/screens/settings.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowBreatheAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: Durations.extralong4);
    _animationController.repeat(reverse: true);
    _glowBreatheAnimation = Tween(begin: 16.0, end: 18.5).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const JsonForm("demographics", nextForm: JsonForm("bfi-10")),
          fullscreenDialog: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingModel = context.watch<RecordingModel>();

    return Scaffold(
      body: pages(context).values.elementAt(currentPageIndex),
      persistentFooterButtons: !recordingModel.isRecording
          ? null
          : [
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: Text(translate("routes.recordings.stop")),
                  onPressed: () => recordingModel.stopRecording(context),
                ),
              ),
            ],
      bottomNavigationBar: NavigationBar(
        destinations: pages(context).keys.toList(),
        onDestinationSelected: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
      ),
    );
  }

  int currentPageIndex = 0;
  Map<Widget, Widget> pages(BuildContext context) {
    return {
      NavigationDestination(icon: const Icon(Icons.map), label: translate("map.title")):
          const MapScreen(),
      NavigationDestination(icon: const Icon(Icons.polyline), label: translate("routes.title")):
          const RoutesScreen(),
      Selector<BluetoothModel, ({BluetoothAdapterState state, BluetoothDevice? device})>(
        selector: (_, model) => (state: model.adapterState, device: model.activeDevice),
        builder: (_, data, __) {
          return NavigationDestination(
            icon: AnimatedBluetoothLogo(
              bluetoothStatus: data.state != BluetoothAdapterState.off
                  ? data.device != null
                      ? BluetoothStatus.connected
                      : BluetoothStatus.available
                  : BluetoothStatus.unavailable,
              animation: _glowBreatheAnimation,
            ),
            label: translate("devices.title_short"),
          );
        },
      ): const DevicesScreen(),
      NavigationDestination(
        icon: const Icon(Icons.settings),
        label: translate("settings.title"),
      ): const SettingsScreen(),
    };
  }
}
