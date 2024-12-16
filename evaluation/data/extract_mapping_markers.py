import csv
import logging
import platform
import subprocess
import sys
from pathlib import Path

import folium
import numpy as np

DEFAULT_MARKERS_CONTENT = "index,rating\n"


def extract_mapping_markers(directory: Path):
    for path in directory.glob("*/recordings/*/rec-*-mapping-*.csv"):
        relative_path = str(path.relative_to(Path(__file__).parent))
        if path.stem.endswith("-markers"):
            continue
        if (markers_path := path.with_stem(path.stem + "-markers")).is_file():
            logging.info("skipping '%s' ('%s' already exists)", relative_path, markers_path.name)
            continue
        if not (image_path := path.with_suffix(".webp")).is_file():
            logging.info("skipping '%s' ('%s' does not exists)", relative_path, image_path.name)
            continue

        logging.info("creating markers file '%s'", markers_path.name)
        markers_path.write_text(DEFAULT_MARKERS_CONTENT, encoding="utf-8", newline="\n")
        logging.info("please manually setup its contents")

        logging.info("showing mapping from '%s'", relative_path)
        process = open_image_in_default_program(image_path)
        show_mapping_in_browser(path)
        process.terminate()

        if markers_path.read_text(encoding="utf-8") == DEFAULT_MARKERS_CONTENT:
            logging.info("markers file '%s' hasn't been updated, aborting", markers_path.name)
            break


def show_mapping_in_browser(path: Path):
    with path.open(encoding="utf-8") as file:
        reader = csv.reader(file)
        next(reader)
        coordinates = np.array([(float(row[0]), float(row[1])) for row in reader])

    folium_map = folium.Map(max_zoom=20)
    folium.PolyLine(coordinates).add_to(folium_map)

    coordinate: tuple[float, float]
    for i, coordinate in enumerate(coordinates):
        folium.CircleMarker(coordinate, radius=2, fill=True, tooltip=str(i)).add_to(folium_map)

    folium_map.fit_bounds(folium_map.get_bounds())  # pyright: ignore[reportArgumentType]
    folium_map.show_in_browser()


def open_image_in_default_program(path: Path):
    match platform.system():
        case "Windows":
            return subprocess.Popen(f'start "" /B /WAIT {path}', shell=True)
        case "Darwin":
            command = "open"
        case "Linux" | _:
            command = "xdg-open"
    return subprocess.Popen([command, str(path)])


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    extract_mapping_markers(Path(__file__).parent)
