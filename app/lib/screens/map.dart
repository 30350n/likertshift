import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_compass/flutter_map_compass.dart";
import "package:latlong2/latlong.dart";
import "package:provider/provider.dart";
import "package:vector_math/vector_math.dart" hide Colors;

import "package:likertshift/api-keys/maptiler.dart" as maptiler;
import "package:likertshift/bluetooth.dart";
import "package:likertshift/location.dart";
import "package:likertshift/recording.dart";

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final mapController = MapController();

  final maptilerUrlLight = "https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}@2x.jpg"
      "?key=${maptiler.apiKey}";
  final maptilerUrlDark = "https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}@2x.png"
      "?key=${maptiler.apiKey}";

  bool followLocation = false;
  bool followRotation = false;

  static const minFollowRotationDistance = 1.0;
  static final upVector = Vector2(0, 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationModel = context.watch<LocationModel>();
    final recordingModel = context.watch<RecordingModel>();
    final activeRecording = recordingModel.activeRecording;

    if ((followLocation || followRotation) && !locationModel.isLocationEnabled) {
      setState(() {
        followLocation = false;
        followRotation = false;
      });
    }

    if (followLocation && locationModel.currentLocation != null) {
      mapController.move(locationModel.currentLocation!, mapController.camera.zoom);
    }

    final direction = locationModel.direction();
    final distance = locationModel.distance();
    if (followRotation && direction != null && (distance ?? 0) > minFollowRotationDistance) {
      mapController.rotate(degrees(direction.angleToSigned(upVector)));
    }

    final activeDevice =
        context.select<BluetoothModel, bool>((model) => model.activeDevice != null);
    final likertshiftValue =
        context.select<BluetoothModel, int?>((model) => model.likertshiftValue);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(52.4294, 13.5303),
              backgroundColor: theme.scaffoldBackgroundColor,
              onMapEvent: locationModel.isLocationEnabled && followLocation
                  ? (event) {
                      if (event is MapEventMove &&
                          event.source != MapEventSource.mapController) {
                        setState(() {
                          followLocation = false;
                        });
                      }
                    }
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    theme.brightness == Brightness.light ? maptilerUrlLight : maptilerUrlDark,
                userAgentPackageName: "com.github.u30350n.likertshift",
              ),
              SafeArea(
                child: GestureDetector(
                  child: Compass(isLocked: followRotation),
                  onLongPress: () {
                    setState(() {
                      followRotation = !followRotation;
                      if (!followRotation) {
                        mapController.rotate(0);
                      }
                    });
                  },
                ),
              ),
              PolylineLayer(
                polylines: [
                  if (recordingModel.isRecording) ...[
                    if (activeRecording?.routePreset != null)
                      Polyline(
                        points: activeRecording!.routePreset!.points,
                        color: Colors.orange.withOpacity(0.4),
                        strokeWidth: 5,
                        useStrokeWidthInMeter: true,
                      ),
                    Polyline(
                      points: activeRecording!.locations,
                      color: theme.colorScheme.onPrimaryFixedVariant,
                      strokeWidth: 3,
                      useStrokeWidthInMeter: true,
                    ),
                  ] else
                    ...recordingModel.routes.where((route) => route.isVisible).map(
                          (route) => Polyline(
                            points: route.points,
                            color: Colors.primaries[route.hashCode % Colors.primaries.length]
                                .withOpacity(0.8),
                            strokeWidth: 5,
                          ),
                        ),
                ],
              ),
              CircleLayer(
                circles: [
                  if (recordingModel.isRecording && activeRecording?.routePreset != null)
                    CircleMarker(
                      point: recordingModel.activeRecording!.routePreset!.points[0],
                      radius: 10,
                      borderStrokeWidth: 3,
                      borderColor: Colors.orange.withOpacity(0.8),
                      color: Colors.white.withOpacity(0.2),
                      useRadiusInMeter: true,
                    ),
                  if (locationModel.isLocationEnabled && locationModel.currentLocation != null)
                    CircleMarker(
                      point: locationModel.currentLocation!,
                      radius: 6,
                      borderStrokeWidth: 1.5,
                      color: theme.colorScheme.onPrimaryFixedVariant,
                      borderColor: Colors.white,
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                if (!locationModel.isLocationEnabled) const LocationOffWidget(),
                if (activeDevice && likertshiftValue != null)
                  LikertshiftValueWidget(likertshiftValue),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (locationModel.isLocationEnabled) {
            setState(() {
              followLocation = !followLocation;
            });
          } else {
            LocationModel.requestLocationService().then((enabled) {
              if (enabled) {
                setState(() {
                  followLocation = !followLocation;
                });
              }
            });
          }
        },
        child: Icon(followLocation ? Icons.gps_fixed : Icons.gps_not_fixed),
      ),
    );
  }
}

class Compass extends StatelessWidget {
  final bool isLocked;

  const Compass({super.key, this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    return MapCompass(
      rotationOffset: -45,
      icon: Stack(
        children: [
          Icon(CupertinoIcons.compass, color: Colors.red.shade600, size: 40),
          Icon(CupertinoIcons.compass_fill, color: Colors.grey.shade200, size: 40),
          Icon(
            CupertinoIcons.circle,
            color: isLocked ? Colors.blue : Colors.grey.shade600,
            size: 40,
          ),
        ],
      ),
    );
  }
}

const likertshiftValueMap = {
  1: "Very Unsatisfied",
  2: "Unsatisfied",
  3: "Neutral",
  4: "Satisfied",
  5: "Very Satisfied",
};

const likertshiftIconMap = {
  1: Icons.sentiment_very_dissatisfied,
  2: Icons.sentiment_dissatisfied,
  3: Icons.sentiment_neutral,
  4: Icons.sentiment_satisfied,
  5: Icons.sentiment_very_satisfied,
};

class LikertshiftValueWidget extends StatelessWidget {
  final int value;

  const LikertshiftValueWidget(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(likertshiftIconMap[value] ?? Icons.error),
            Text(likertshiftValueMap[value] ?? "None", style: theme.textTheme.headlineSmall),
            Text("[ $value ]", style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class LocationOffWidget extends StatelessWidget {
  const LocationOffWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;

    final (color, backgroundColor, borderColor) = switch (theme.brightness) {
      Brightness.light => (colors.onError, colors.error, colors.errorContainer),
      Brightness.dark => (colors.onErrorContainer, colors.errorContainer, colors.error),
    };

    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: borderColor.withOpacity(0.8)),
      foregroundColor: color,
      textStyle: theme.textTheme.titleSmall,
      backgroundColor: backgroundColor.withOpacity(0.8),
    );

    return Center(
      child: OutlinedButton(
        style: buttonStyle,
        onPressed: LocationModel.requestLocationService,
        child: const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Icon(Icons.error, size: 16),
            Text("Location Service is disabled"),
          ],
        ),
      ),
    );
  }
}
