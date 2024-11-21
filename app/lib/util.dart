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

Future<Directory> getResultsDirectory() async {
  final parent = await getStorageDirectory();
  return Directory("${parent.path}/results").create();
}

String uniquePath(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return path;
  }
  final nameRegex = RegExp(r"^" + file.stem + r"_(\d+)\" + file.suffix + r"$");
  final maxIndex = file.parent
      .listSync()
      .map((entry) => nameRegex.firstMatch(entry.name)?.group(1))
      .whereType<String>()
      .map(int.parse)
      .fold(0, max);

  return "${file.parent.path}/${file.stem}_${maxIndex + 1}${file.suffix}";
}

extension BaseNameExtension on FileSystemEntity {
  String get name => uri.pathSegments.last;
  String get stem => (name.split(".")..removeLast()).join(".");
  String get suffix => name.contains(".") ? ".${name.split(".").last}" : "";
}

extension PrettyDurationExtension on Duration {
  String pretty() {
    return toString().substring(inHours > 0 ? 0 : 2).split(".").first.replaceAll(":", " : ");
  }
}

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + substring(1);
  }

  String transformed(String Function(String) transform) {
    return transform(this);
  }
}

extension LatLngExtension on LatLng {
  static const earthRadius = 6378137.0;
  double distanceTo(LatLng other) {
    final cosLat = cos(radians(latitude));
    final cosLatOther = cos(radians(other.latitude));
    final cosLatDelta = cos(radians(other.latitude - latitude));
    final cosLongDelta = cos(radians(other.longitude - longitude));

    return 2.0 *
        earthRadius *
        asin(sqrt((1 - cosLatDelta + cosLat * cosLatOther * (1 - cosLongDelta)) * 0.5));
  }

  Vector2 mercator() {
    return Vector2(radians(longitude), log(tan(pi / 4 + radians(latitude) / 2)));
  }

  Vector2 mercatorDirectionTo(LatLng other) {
    return (other.mercator() - mercator()).normalized();
  }

  static final upVector = Vector2(0, 1);
  double mercatorAngleTo(LatLng other) {
    return mercatorDirectionTo(other).angleToSigned(upVector);
  }
}

class SeperatedListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;

  const SeperatedListView({super.key, required this.children, this.padding, this.spacing});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (_, index) => children[index],
      separatorBuilder: (_, __) => SizedBox(height: spacing ?? 10),
      itemCount: children.length,
    );
  }
}

class FormListView extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  const FormListView({
    super.key,
    required this.formKey,
    required this.children,
    this.padding,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: SeperatedListView(
        padding: padding,
        spacing: spacing,
        children: children,
      ),
    );
  }
}
