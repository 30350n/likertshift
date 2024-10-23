import "dart:math";
import "package:latlong2/latlong.dart";
import "package:vector_math/vector_math.dart";

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + substring(1);
  }
}

const earthRadius = 6378137.0;

extension LatLngExtension on LatLng {
  double distance(LatLng other) {
    final cosLat = cos(radians(latitude));
    final cosLatOther = cos(radians(other.latitude));
    final cosLatDelta = cos(radians(other.latitude - latitude));
    final cosLongDelta = cos(radians(other.longitude - longitude));

    return 2.0 *
        earthRadius *
        asin(sqrt((1 - cosLatDelta + cosLat * cosLatOther * (1 - cosLongDelta)) * 0.5));
  }
}
