import "package:flutter/material.dart";

import "package:likertshift/screens/map.dart";
import "package:likertshift/screens/settings.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
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
      const NavigationDestination(icon: Icon(Icons.polyline), label: "Routes"): Scaffold(
        appBar: AppBar(leading: const Icon(Icons.polyline), title: const Text("Routes")),
      ),
      const NavigationDestination(icon: Icon(Icons.bluetooth), label: "Devices"): Scaffold(
        appBar: AppBar(leading: const Icon(Icons.bluetooth), title: const Text("Devices")),
      ),
      const NavigationDestination(icon: Icon(Icons.settings), label: "Settings"):
          const SettingsScreen(),
    };
  }
}
