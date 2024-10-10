import "package:flutter/material.dart";

import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";

import "package:likertshift/api-keys/maptiler.dart" as maptiler;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final tileProviderUrlLight =
      "https://api.maptiler.com/maps/openstreetmap/256/{z}/{x}/{y}@2x.jpg"
      "?key=${maptiler.apiKey}";
  final tileProviderUrlDark =
      "https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}@2x.png"
      "?key=${maptiler.apiKey}";

  bool followLocation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(52.4294, 13.5303),
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          children: [
            TileLayer(
              urlTemplate: theme.brightness == Brightness.light
                  ? tileProviderUrlLight
                  : tileProviderUrlDark,
              userAgentPackageName: "com.github.u30350n.likertshift",
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  color: Colors.orange,
                  strokeWidth: 2,
                  points: const [
                    LatLng(52.429967, 13.530978),
                    LatLng(52.429323, 13.529550),
                    LatLng(52.429076, 13.528675),
                    LatLng(52.428568, 13.525787),
                    LatLng(52.428495, 13.525114),
                    LatLng(52.428172, 13.519515),
                    LatLng(52.427277, 13.519805),
                    LatLng(52.427189, 13.519721),
                    LatLng(52.427126, 13.519621),
                    LatLng(52.427105, 13.519517),
                    LatLng(52.427066, 13.518623),
                    LatLng(52.427296, 13.518037),
                    LatLng(52.427333, 13.518072),
                    LatLng(52.427093, 13.518709),
                    LatLng(52.426717, 13.519451),
                    LatLng(52.426467, 13.519837),
                    LatLng(52.426215, 13.520169),
                    LatLng(52.425919, 13.520492),
                    LatLng(52.425658, 13.520694),
                    LatLng(52.425333, 13.520885),
                    LatLng(52.425003, 13.521046),
                    LatLng(52.424570, 13.521199),
                    LatLng(52.423931, 13.521386),
                    LatLng(52.423706, 13.521380),
                    LatLng(52.423578, 13.521380),
                    LatLng(52.423503, 13.521437),
                    LatLng(52.422802, 13.521507),
                    LatLng(52.422049, 13.521517),
                    LatLng(52.421313, 13.521474),
                    LatLng(52.420569, 13.521467),
                    LatLng(52.420216, 13.521528),
                    LatLng(52.419877, 13.521640),
                    LatLng(52.419358, 13.521922),
                    LatLng(52.419591, 13.523941),
                    LatLng(52.420253, 13.524485),
                    LatLng(52.420284, 13.524494),
                    LatLng(52.420345, 13.524444),
                    LatLng(52.420409, 13.524406),
                    LatLng(52.420478, 13.524417),
                    LatLng(52.420545, 13.524454),
                    LatLng(52.421563, 13.525296),
                    LatLng(52.421717, 13.525385),
                    LatLng(52.421879, 13.525445),
                    LatLng(52.422413, 13.525600),
                    LatLng(52.423043, 13.525820),
                    LatLng(52.423819, 13.526102),
                    LatLng(52.424595, 13.526350),
                    LatLng(52.426326, 13.526607),
                    LatLng(52.426397, 13.526469),
                    LatLng(52.426617, 13.526490),
                    LatLng(52.426445, 13.529021),
                    LatLng(52.426814, 13.529084),
                    LatLng(52.426922, 13.529126),
                    LatLng(52.426992, 13.529249),
                    LatLng(52.428826, 13.532645),
                    LatLng(52.429730, 13.531337),
                    LatLng(52.429967, 13.530978),
                  ],
                ),
                Polyline(
                  color: Colors.red,
                  strokeWidth: 2,
                  points: const [
                    LatLng(52.429972, 13.530980),
                    LatLng(52.430328, 13.531749),
                    LatLng(52.430929, 13.533423),
                    LatLng(52.432261, 13.535499),
                    LatLng(52.432866, 13.536479),
                    LatLng(52.434289, 13.538746),
                    LatLng(52.434367, 13.538926),
                    LatLng(52.434621, 13.538498),
                    LatLng(52.437364, 13.534343),
                    LatLng(52.438634, 13.532418),
                    LatLng(52.439856, 13.530516),
                    LatLng(52.439925, 13.530456),
                    LatLng(52.440025, 13.530213),
                    LatLng(52.440128, 13.530060),
                    LatLng(52.440177, 13.530144),
                    LatLng(52.441072, 13.531691),
                    LatLng(52.442092, 13.530320),
                    LatLng(52.442796, 13.529405),
                    LatLng(52.445479, 13.525431),
                    LatLng(52.445799, 13.524855),
                    LatLng(52.446114, 13.524271),
                    LatLng(52.446035, 13.524059),
                    LatLng(52.445974, 13.523754),
                    LatLng(52.445907, 13.523551),
                    LatLng(52.445201, 13.522296),
                    LatLng(52.445086, 13.522169),
                    LatLng(52.444254, 13.520670),
                    LatLng(52.443421, 13.519153),
                    LatLng(52.443304, 13.518954),
                    LatLng(52.443176, 13.518795),
                    LatLng(52.442462, 13.517475),
                    LatLng(52.441735, 13.516162),
                    LatLng(52.441545, 13.516013),
                    LatLng(52.441353, 13.515658),
                    LatLng(52.441124, 13.515188),
                    LatLng(52.441326, 13.514365),
                    LatLng(52.441387, 13.513997),
                    LatLng(52.441448, 13.513784),
                    LatLng(52.441478, 13.513582),
                    LatLng(52.441566, 13.513264),
                    LatLng(52.441411, 13.512587),
                    LatLng(52.441169, 13.512087),
                    LatLng(52.440889, 13.512021),
                    LatLng(52.440378, 13.511712),
                    LatLng(52.440277, 13.511668),
                    LatLng(52.440196, 13.511570),
                    LatLng(52.438213, 13.510858),
                    LatLng(52.436174, 13.510678),
                    LatLng(52.434112, 13.510501),
                    LatLng(52.434023, 13.513232),
                    LatLng(52.433957, 13.513659),
                    LatLng(52.433933, 13.514431),
                    LatLng(52.433651, 13.516165),
                    LatLng(52.433391, 13.517754),
                    LatLng(52.432725, 13.517981),
                    LatLng(52.431301, 13.518471),
                    LatLng(52.428176, 13.519522),
                    LatLng(52.428495, 13.525278),
                    LatLng(52.429247, 13.529377),
                    LatLng(52.429972, 13.530980),
                  ],
                ),
                Polyline(
                  color: Colors.blue,
                  strokeWidth: 2,
                  points: const [
                    LatLng(52.426542, 13.536059),
                    LatLng(52.426530, 13.536536),
                    LatLng(52.426033, 13.536452),
                    LatLng(52.425769, 13.541061),
                    LatLng(52.425653, 13.543679),
                    LatLng(52.425694, 13.544412),
                    LatLng(52.425846, 13.545128),
                    LatLng(52.426069, 13.545707),
                    LatLng(52.426382, 13.546286),
                    LatLng(52.426212, 13.546565),
                    LatLng(52.426152, 13.546469),
                    LatLng(52.425368, 13.547857),
                    LatLng(52.425745, 13.551230),
                    LatLng(52.426604, 13.552895),
                    LatLng(52.427336, 13.551581),
                    LatLng(52.428443, 13.550059),
                    LatLng(52.428845, 13.550698),
                    LatLng(52.429005, 13.550493),
                    LatLng(52.430604, 13.548017),
                    LatLng(52.432014, 13.545784),
                    LatLng(52.433721, 13.543294),
                    LatLng(52.434341, 13.542455),
                    LatLng(52.434839, 13.541876),
                    LatLng(52.435288, 13.541270),
                    LatLng(52.434447, 13.539070),
                    LatLng(52.434295, 13.538763),
                    LatLng(52.432175, 13.535387),
                    LatLng(52.430874, 13.533265),
                    LatLng(52.430319, 13.531727),
                    LatLng(52.429977, 13.530984),
                    LatLng(52.429722, 13.531345),
                    LatLng(52.426542, 13.536059),
                  ],
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 20.0,
          bottom: 20.0,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                followLocation = !followLocation;
              });
            },
            child: Icon(
              followLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
            ),
          ),
        ),
      ],
    );
  }
}
