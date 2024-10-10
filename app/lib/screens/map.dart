import "package:flutter/material.dart";

import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";

import "package:likertshift/api-keys/maptiler.dart" as maptiler;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final tileProviderUrlLight =
      "https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}@2x.jpg"
      "?key=${maptiler.apiKey}";
  final tileProviderUrlDark =
      "https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}@2x.png"
      "?key=${maptiler.apiKey}";

  bool followLocation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(52.4294, 13.5303),
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          children: [
            TileLayer(
              urlTemplate: theme.brightness == Brightness.light
                  ? tileProviderUrlLight
                  : tileProviderUrlDark,
              userAgentPackageName: "com.github.u30350n.likertshift",
            ),
          ],
        ),
        Positioned(
          right: 20.0,
          bottom: 20.0,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                followLocation = !followLocation;
              });
            },
            child: Icon(
              followLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
            ),
          ),
        ),
      ],
    );
  }
}
