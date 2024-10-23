import "package:flutter/material.dart";

import "package:flutter_blue_plus/flutter_blue_plus.dart";
import "package:provider/provider.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/demographics.dart";
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
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<DemographicsModel>().isValid()) {
      return const Demographics();
    }

    return Scaffold(
      body: pages(context).values.elementAt(currentPageIndex),
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
      const NavigationDestination(icon: Icon(Icons.map), label: "Map"): const MapScreen(),
      const NavigationDestination(icon: Icon(Icons.polyline), label: "Routes"):
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
            label: "Devices",
          );
        },
      ): const DevicesScreen(),
      const NavigationDestination(icon: Icon(Icons.settings), label: "Settings"):
          const SettingsScreen(),
    };
  }
}
