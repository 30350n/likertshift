import "dart:async";
import "dart:io";

import "package:flutter/material.dart";

import "package:flutter_blue_plus/flutter_blue_plus.dart";

import "package:likertshift/colors.dart";

// TODO: don't hardcode this
const knownDevices = [
  "EF:17:58:1E:0F:9E",
];

class BluetoothModel with ChangeNotifier {
  static final Guid serviceUUID = Guid.fromString("9e7312e0-2354-11eb-9f10-fbc30a621337");

  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;

  late StreamSubscription<List<ScanResult>> _scanSubscription;
  final Set<BluetoothDevice> _devices = {};
  List<BluetoothDevice> get devices => List.unmodifiable(_devices);

  late StreamSubscription<bool> _isScanningSubscription;
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  BluetoothDevice? _activeDevice;
  BluetoothDevice? get activeDevice => _activeDevice;
  BluetoothModel() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      switch (state) {
        case BluetoothAdapterState.on:
          if (_adapterState == BluetoothAdapterState.unknown) {
            startScan();
          }
        case BluetoothAdapterState.turningOn:
          startScan();

        case BluetoothAdapterState.turningOff:
          stopScan();

        default:
      }

      _adapterState = state;
      notifyListeners();
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        _devices.addAll(results.map((result) => result.device));
        notifyListeners();
      },
    );

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((value) {
      _isScanning = value;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    _devices.clear();

    if (Platform.isAndroid) {
      unawaited(
        FlutterBluePlus.bondedDevices.then((devices) {
          _devices.addAll(
            devices.where((device) => knownDevices.contains(device.remoteId.str)),
          );
          notifyListeners();
        }),
      );
    }
    unawaited(
      FlutterBluePlus.systemDevices.then((devices) {
        _devices.addAll(
          devices.where(
            (device) =>
                device.servicesList.map((service) => service.uuid).contains(serviceUUID),
          ),
        );
        notifyListeners();
      }),
    );

    return FlutterBluePlus.startScan(
      withServices: [serviceUUID],
      timeout: const Duration(seconds: 10),
    );
  }

  Future<void> stopScan() async {
    return FlutterBluePlus.stopScan();
  }

  @override
  void dispose() {
    stopScan();
    _isScanningSubscription.cancel();
    _scanSubscription.cancel();
    _adapterStateSubscription.cancel();
    super.dispose();
  }
}

class BluetoothLogo extends AnimatedWidget {
  final BluetoothAdapterState adapterState;
  final BluetoothDevice? activeDevice;
  const BluetoothLogo({
    super.key,
    required this.adapterState,
    required this.activeDevice,
    required Animation<double> animation,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    return adapterState == BluetoothAdapterState.off
        ? Icon(Icons.bluetooth_disabled, color: theme.disabledColor)
        : activeDevice == null
            ? const Icon(Icons.bluetooth_connected)
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (appColors?.connectedColor ?? Colors.white).withOpacity(0.7),
                      blurRadius: animation.value,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(Icons.bluetooth, color: appColors?.connectedColor),
              );
  }
}
