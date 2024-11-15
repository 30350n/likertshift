import "package:flutter/material.dart";

import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_translate/flutter_translate.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:latlong2/latlong.dart";
import "package:provider/provider.dart";

import "package:likertshift/recording.dart";
import "package:likertshift/util.dart";

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingModel = context.watch<RecordingModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.polyline),
          title: Text(translate("routes.title")),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Wrap(
                  spacing: 8,
                  children: [
                    const Icon(Icons.route, size: 20),
                    Text(translate("routes.presets")),
                  ],
                ),
              ),
              Tab(
                child: Wrap(
                  spacing: 8,
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 20),
                    Text(translate("routes.recordings.title")),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              children: recordingModel.routes
                  .map(
                    (route) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 16, right: 6),
                        leading: Icon(route.icon),
                        title: Text(route.name),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(route.lengthString),
                            IconButton(
                              icon: Icon(
                                route.isVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                route.isVisible = !route.isVisible;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ListView(
              children: recordingModel.recordings
                  .map((recording) => Card(child: ListTile(title: Text(recording.name))))
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: recordingModel.isRecording
            ? null
            : FloatingActionButton(
                tooltip: translate("routes.recordings.new_hint"),
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RouteSelection(recordingModel)),
                  );
                },
              ),
      ),
    );
  }
}

class RouteSelection extends StatelessWidget {
  final _formKey = GlobalKey<FormBuilderState>();
  final RecordingModel recordingModel;

  RouteSelection(this.recordingModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate("routes.recordings.options.title")),
      ),
      body: FormListView(
        formKey: _formKey,
        children: [
          FormBuilderDropdown(
            name: "route_preset",
            decoration: InputDecoration(
              label: Text(translate("routes.recordings.options.route_preset")),
            ),
            items: [null, ...recordingModel.routes]
                .map(
                  (route) => DropdownMenuItem(
                    value: route,
                    child: Text(
                      route == null ? "None" : "${route.name} (${route.lengthString})",
                    ),
                  ),
                )
                .toList(),
          ),
          FormBuilderDropdown(
            name: "method",
            decoration: InputDecoration(
              label: Text(translate("routes.recordings.options.method.title")),
            ),
            validator: FormBuilderValidators.required(),
            items: RecordingMethod.values
                .map(
                  (method) => DropdownMenuItem(
                    value: method,
                    child: Text(translate(method.description)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      persistentFooterButtons: [
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.fiber_manual_record),
            label: Text(translate("routes.recordings.options.start")),
            onPressed: () {
              final formState = _formKey.currentState;
              if (formState?.validate() ?? false) {
                recordingModel.startRecording(
                  formState!.fields["method"]!.value,
                  routePreset: formState.fields["route_preset"]?.value,
                );
                Navigator.pop(context);
              }
            },
          ),
        ),
      ],
    );
  }
}

class Route {
  final RecordingModel recordingModel;
  final String name;
  final IconData? icon;
  final List<LatLng> points;

  bool _isVisible = false;
  bool get isVisible => _isVisible;
  set isVisible(value) {
    _isVisible = value;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    recordingModel.notifyListeners();
  }

  String get id => name.replaceAll(" ", "_").toLowerCase();

  Color get color =>
      Colors.primaries[hashCode % Colors.primaries.length].withValues(alpha: 0.75);

  double get length => [
        for (int i in Iterable.generate(points.length - 1)) points[i].distanceTo(points[i + 1]),
      ].fold(0, (p, c) => p + c);
  String get lengthString => "${(length * 0.001).toStringAsFixed(1)} km";

  Route(this.recordingModel, {required this.name, this.icon, required this.points});

  Route.fromJson(this.recordingModel, Map<String, dynamic> json)
      : name = json["name"] as String,
        icon = IconData(int.tryParse(json["icon"]) ?? 0xf0552, fontFamily: "MaterialIcons"),
        points = (json["coordinates"] as List<dynamic>)
            .map((coordinates) => LatLng(coordinates[1], coordinates[0]))
            .toList();

  Marker getStartMarker({Color? color, double? size}) {
    final markerSize = size ?? 64;
    return Marker(
      alignment: Alignment.center,
      width: markerSize,
      height: markerSize,
      point: points.first,
      child: Transform.rotate(
        angle: points[0].mercatorAngleTo(points[1]),
        child: Icon(
          Icons.arrow_drop_up_rounded,
          size: markerSize,
          color: color ?? this.color.withValues(alpha: 1),
          grade: 4,
        ),
      ),
    );
  }
}
