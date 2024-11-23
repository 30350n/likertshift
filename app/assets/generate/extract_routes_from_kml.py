import json
from argparse import ArgumentParser
from pathlib import Path

from error_helper import *
from fastkml import KML, Placemark
from fastkml.geometry import LineString, Polygon

def extract_routes_from_kml(path: Path):
    path = path.expanduser().resolve()
    if not path.is_file():
        return error(f"KML file \"{path}\" does not exist")

    kml = KML()
    kml.from_string(path.read_bytes())

    if not (document := next(kml.features())):
        return warning("KML file is empty")

    for placemark in document.features():
        name = str(placemark.name or placemark.id)
        if not isinstance(placemark, Placemark):
            warning(f"skipping non Placemark feature ({name})")
            continue

        if not isinstance(placemark.geometry, (Polygon, LineString)):
            warning(
                f"skipping Placemark (geometry \"{placemark.geometry._type}\" is not a Polygon)"
            )
            continue

        route_path = (Path("../routes") / name.lower().replace(" ", "_")).with_suffix(".json")

        info(f"writing polygon \"{name}\" to \"{route_path}\"")

        if isinstance(placemark.geometry, Polygon):
            coords = placemark.geometry.exterior.coords
        elif isinstance(placemark.geometry, LineString):
            coords = placemark.geometry.coords

        route_path.write_text(json.dumps(
            {
                "name": str(placemark.name or placemark.id),
                "icon": "0xf0552",
                "coordinates": [coord[:2] for coord in coords],
            },
            indent=4,
        ))

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("kml_path", type=Path)
    args = parser.parse_args()

    extract_routes_from_kml(args.kml_path)
