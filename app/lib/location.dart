import "dart:async";

import "package:flutter/material.dart";

import "package:geolocator/geolocator.dart";
import "package:latlong2/latlong.dart";

class LocationModel with ChangeNotifier {
  bool _isLocationEnabled = false;
  bool get isLocationEnabled => _isLocationEnabled;
  late StreamSubscription _isLocationEnabledSubscription;

  LatLng? _currentLocation = const LatLng(0, 0);
  LatLng? get currentLocation => _currentLocation;

  late StreamSubscription _locationUpdateSubscription;

  LocationModel() {
    Geolocator.isLocationServiceEnabled().then(
      (isLocationEnabled) {
        _isLocationEnabled = isLocationEnabled;
        notifyListeners();
      },
    );

    _isLocationEnabledSubscription = Geolocator.getServiceStatusStream().listen(
      (status) {
        _isLocationEnabled = status == ServiceStatus.enabled;
        if (!_isLocationEnabled) {
          _currentLocation = null;
        }
        notifyListeners();
      },
    );

    _locationUpdateSubscription = Geolocator.getPositionStream().listen(
      (position) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      },
      cancelOnError: false,
      onError: (e) {},
    );
  }

  @override
  void dispose() {
    _locationUpdateSubscription.cancel();
    _isLocationEnabledSubscription.cancel();
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
