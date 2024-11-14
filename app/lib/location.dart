import "dart:async";

import "package:flutter/material.dart";

import "package:geolocator/geolocator.dart";
import "package:latlong2/latlong.dart";

class LocationModel with ChangeNotifier {
  bool _isLocationEnabled = false;
  bool get isLocationEnabled => _isLocationEnabled;
  StreamSubscription? _isLocationEnabledSubscription;

  LatLng? previousLocation = const LatLng(0, 0);
  LatLng? _currentLocation = const LatLng(0, 0);
  LatLng? get currentLocation => _currentLocation;

  StreamSubscription? _locationUpdateSubscription;

  static Future<LocationModel> create() async {
    final model = LocationModel();
    await model.init();
    return model;
  }

  Future<void> init() async {
    if (await Geolocator.isLocationServiceEnabled()) {
      _isLocationEnabled = true;
      notifyListeners();
    }

    _isLocationEnabledSubscription = Geolocator.getServiceStatusStream().listen(
      (status) {
        _isLocationEnabled = status == ServiceStatus.enabled;
        if (!_isLocationEnabled) {
          previousLocation = null;
          _currentLocation = null;
        }
        notifyListeners();
      },
    );

    _locationUpdateSubscription = Geolocator.getPositionStream().listen(
      (position) {
        previousLocation = _currentLocation;
        _currentLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      },
      cancelOnError: false,
      onError: (e) {},
    );
  }

  @override
  void dispose() {
    _locationUpdateSubscription?.cancel();
    _isLocationEnabledSubscription?.cancel();
    super.dispose();
  }

  static Future<bool> requestLocationService() async {
    switch (await Geolocator.requestPermission()) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        try {
          await Geolocator.getCurrentPosition();
        } on Exception {
          return false;
        }
      default:
    }
    return Geolocator.isLocationServiceEnabled();
  }
}
