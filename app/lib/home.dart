import "package:flutter/material.dart";

import "package:adaptive_theme/adaptive_theme.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";

import "package:likertshift/api-keys/maptiler.dart" as maptiler;

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(initialCenter: LatLng(52.4294, 13.5303)),
      children: [
        TileLayer(
          urlTemplate: AdaptiveTheme.of(context).brightness == Brightness.light
              ? "https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}@2x.jpg?key=${maptiler.apiKey}"
              : "https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}@2x.png?key=${maptiler.apiKey}",
          userAgentPackageName: "com.github.u30350n.likertshift",
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: const LatLng(52.4294, 13.5303),
              child: Icon(
                Icons.location_on,
                color: AdaptiveTheme.of(context).theme.colorScheme.primary,
                size: 48.0,
              ),
              height: 60,
            ),
          ],
        ),
      ],
    );
  }
}
