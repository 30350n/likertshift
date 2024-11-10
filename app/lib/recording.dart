import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

import "package:latlong2/latlong.dart";
import "package:record/record.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/location.dart";
import "package:likertshift/screens/routes.dart";
import "package:likertshift/util.dart";

enum RecordingMethod {
  device(description: "routes.recordings.options.method.01_device"),
  audio(description: "routes.recordings.options.method.02_audio"),
  mapping(description: "routes.recordings.options.method.03_manual");

  final String description;

  const RecordingMethod({required this.description});
}

class Recording {
  final DateTime startTime = DateTime.now();
  final RecordingMethod method;
  final Route? routePreset;

  String get name => "rec-${shortHash(startTime)}-${method.name}-${routePreset?.id ?? "null"}";

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

  final List<Route> _routes = [];
  List<Route> get routes => List.unmodifiable(_routes);

  final audioRecorder = AudioRecorder();

  final List<Recording> _recordings = [];
  List<Recording> get recordings => List.unmodifiable(_recordings);

  Recording? _activeRecording;
  Recording? get activeRecording => _activeRecording;
  bool get isRecording => activeRecording != null;

  static Future<RecordingModel> create(
    BluetoothModel bluetoothModel,
    LocationModel locationModel,
  ) async {
    final model = RecordingModel(
      bluetoothModel: bluetoothModel,
      locationModel: locationModel,
    );
    await model.loadAssets();
    return model;
  }

  Future<void> loadAssets() async {
    final routePaths = json
        .decode(await rootBundle.loadString("AssetManifest.json"))
        .keys
        .where((String path) => path.startsWith("assets/routes/"));

    for (String path in routePaths) {
      try {
        _routes.add(Route.fromJson(this, json.decode(await rootBundle.loadString(path))));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> startRecording(RecordingMethod method, {Route? routePreset}) async {
    if (isRecording) {
      return;
    }

    if (method == RecordingMethod.audio && !await audioRecorder.hasPermission()) {
      return;
    }

    final recording = Recording(routePreset: routePreset, method: method);
    await recording.start();
    if (method == RecordingMethod.audio) {
      const recordConfig = RecordConfig(
        encoder: AudioEncoder.flac,
        autoGain: true,
        numChannels: 1,
      );
      await audioRecorder.start(
        recordConfig,
        path: "${(await getRecordingDirectory()).path}/${recording.name}.flac",
      );
    }

    _activeRecording = recording;
    locationModel.addListener(onLocationUpdate);
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!isRecording) {
      return;
    }

    await _activeRecording!.stop();
    if (_activeRecording!.method == RecordingMethod.audio) {
      await audioRecorder.stop();
    }

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
