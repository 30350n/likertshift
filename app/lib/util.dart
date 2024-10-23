import "dart:io";
import "dart:math";

import "package:flutter/material.dart";

import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:latlong2/latlong.dart";
import "package:path_provider/path_provider.dart";
import "package:vector_math/vector_math.dart";

Future<Directory> getStorageDirectory() async {
  return await getExternalStorageDirectory() ?? getApplicationDocumentsDirectory();
}

Future<Directory> getRecordingDirectory() async {
  final parent = await getStorageDirectory();
  return Directory("${parent.path}/recordings").create();
}

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

class FormListView extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;
  const FormListView({
    super.key,
    required this.formKey,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: ListView.separated(
        padding: padding,
        itemBuilder: (_, index) => children[index],
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemCount: children.length,
      ),
    );
  }
}
