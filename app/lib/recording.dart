import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:io";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Route;
import "package:flutter/services.dart";

import "package:flutter_translate/flutter_translate.dart";
import "package:latlong2/latlong.dart";
import "package:record/record.dart";

import "package:likertshift/bluetooth.dart";
import "package:likertshift/forms.dart";
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

  static const _audioAmplitudeSamples = 64;
  final ListQueue<double> _audioAmplitudeMemory = ListQueue(_audioAmplitudeSamples);
  StreamSubscription<Amplitude>? _audioAmplitudeSubscription;
  double? _audioAmplitude;
  double? get audioAmplitude => _audioAmplitude;
  double? get audioAmplitudeNormalized {
    if (_audioAmplitude == null) {
      return null;
    }
    final amplitudeMin = _audioAmplitudeMemory.reduce(min);
    final amplitudeMax = _audioAmplitudeMemory.reduce(max);
    return (_audioAmplitude! - amplitudeMin) / (amplitudeMax - amplitudeMin);
  }

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
      _audioAmplitudeSubscription = audioRecorder.onAmplitudeChanged(Durations.short2).listen(
        (amplitude) {
          _audioAmplitude = amplitude.current;
          if (_audioAmplitudeMemory.length >= _audioAmplitudeSamples) {
            _audioAmplitudeMemory.removeFirst();
          }
          _audioAmplitudeMemory.addLast(amplitude.current);
          notifyListeners();
        },
      );
    }

    _activeRecording = recording;
    locationModel.addListener(onLocationUpdate);
    notifyListeners();
  }

  Future<void> stopRecording(BuildContext context) async {
    if (!isRecording) {
      return;
    }

    await activeRecording!.stop();

    if (activeRecording!.method == RecordingMethod.audio) {
      await _audioAmplitudeSubscription?.cancel();
      _audioAmplitudeSubscription = null;
      _audioAmplitude = null;
      _audioAmplitudeMemory.clear();
      await audioRecorder.stop();
    }

    locationModel.removeListener(onLocationUpdate);
    _recordings.add(activeRecording!);

    final recordingMethod = activeRecording!.method;
    final prefix = activeRecording!.name;

    _activeRecording = null;
    notifyListeners();

    final ueq = JsonForm("ueq_01_attractiveness", prefix: prefix);
    final tlx = JsonForm("tlx", prefix: prefix, nextForm: ueq);
    final weatherConditions = JsonForm("weather-conditions", prefix: prefix, nextForm: tlx);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => recordingMethod == RecordingMethod.mapping
              ? ManualMappingScreen(nextForm: weatherConditions)
              : weatherConditions,
        ),
      );
    }
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

class ManualMappingScreen extends StatelessWidget {
  final Widget? nextForm;

  const ManualMappingScreen({super.key, this.nextForm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translate("routes.recordings.options.method.03_manual")),
          automaticallyImplyLeading: false,
        ),
        body: SeperatedListView(
          children: [
            Text(
              translate("routes.recordings.manual_mapping_task"),
              style: theme.textTheme.titleMedium,
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
            ElevatedButton(
              child: Text(translate("common.done").toUpperCase()),
              onPressed: () {
                if (nextForm != null) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => nextForm!),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
