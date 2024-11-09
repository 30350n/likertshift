import "dart:async";

import "package:flutter/material.dart";

import "package:geolocator/geolocator.dart";
import "package:latlong2/latlong.dart";
import "package:vector_math/vector_math.dart";

import "package:likertshift/util.dart";

class LocationModel with ChangeNotifier {
  bool _isLocationEnabled = false;
  bool get isLocationEnabled => _isLocationEnabled;
  StreamSubscription? _isLocationEnabledSubscription;

  LatLng? _previousLocation = const LatLng(0, 0);
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
          _previousLocation = null;
          _currentLocation = null;
        }
        notifyListeners();
      },
    );

    _locationUpdateSubscription = Geolocator.getPositionStream().listen(
      (position) {
        _previousLocation = _currentLocation;
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

  Vector2? direction() {
    if (_currentLocation == null || _previousLocation == null) {
      return null;
    }
    return (_currentLocation!.mercator() - _previousLocation!.mercator()).normalized();
  }

  double? distance() {
    if (_currentLocation == null || _previousLocation == null) {
      return null;
    }
    return _currentLocation!.distance(_previousLocation!);
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
