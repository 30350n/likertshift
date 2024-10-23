import "dart:io";

import "package:flutter/foundation.dart";

import "package:latlong2/latlong.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/location.dart";
import "package:likertshift/screens/routes.dart";
import "package:likertshift/util.dart";

enum RecordingMethod {
  device(description: "Feedbike Device"),
  audio(description: "Audio"),
  mapping(description: "Manual Mapping");

  final String description;

  const RecordingMethod({required this.description});
}

class Recording {
  final DateTime startTime = DateTime.now();
  final RecordingMethod method;
  final Route? routePreset;

  String get name => "rec-${shortHash(startTime)}-${method.name}-${routePreset?.id ?? "none"}";

  final List<(LatLng, Duration, dynamic)> _points = [];
  List<(LatLng, Duration, dynamic)> get points => List.unmodifiable(_points);
  List<LatLng> get locations => _points.map((point) => point.$1).toList();

  Recording({required this.routePreset, required this.method});

  IOSink? _fileSink;

  Future<void> start() async {
    final directory = await getRecordingDirectory();
    final file = File("${directory.path}/$name.csv");
    await file.writeAsString(
      "${[shortHash(startTime), method.name, routePreset?.id ?? ""].join(", ")}\n",
    );
    _fileSink = file.openWrite(mode: FileMode.append);
  }

  Future<void> stop() async {
    await _fileSink?.close();
  }

  Future<void> addPoint(LatLng location, dynamic data) async {
    final relativeTimestamp = DateTime.now().difference(startTime);
    _points.add((location, relativeTimestamp, data));

    assert(_fileSink != null);
    _fileSink?.write(
      "${[
        location.latitude.toStringAsExponential(),
        location.longitude.toStringAsExponential(),
        relativeTimestamp.inMilliseconds.toString(),
        data?.toString() ?? "",
      ].join(", ")}\n",
    );
    await _fileSink?.flush();
  }
}

class RecordingModel with ChangeNotifier {
  final BluetoothModel bluetoothModel;
  final LocationModel locationModel;

  RecordingModel({required this.bluetoothModel, required this.locationModel});

  final List<Recording> _recordings = [];
  List<Recording> get recordings => List.unmodifiable(_recordings);

  Recording? _activeRecording;
  Recording? get activeRecording => _activeRecording;
  bool get isRecording => activeRecording != null;

  Future<void> startRecording(RecordingMethod method, {Route? routePreset}) async {
    if (isRecording) {
      return;
    }

    final recording = Recording(routePreset: routePreset, method: method);
    await recording.start();
    _activeRecording = recording;
    locationModel.addListener(onLocationUpdate);
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!isRecording) {
      return;
    }

    await _activeRecording!.stop();

    locationModel.removeListener(onLocationUpdate);
    _recordings.add(_activeRecording!);
    _activeRecording = null;
    notifyListeners();
  }

  void onLocationUpdate() {
    if (!isRecording) {
      return;
    }

    final location = locationModel.currentLocation;
    final data = bluetoothModel.likertshiftValue;
    if (location != null) {
      activeRecording?.addPoint(location, data);
    }
    notifyListeners();
  }
}
