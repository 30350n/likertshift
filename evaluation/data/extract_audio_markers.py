import csv
import logging
import subprocess
import sys
from pathlib import Path

CUEPOINTLIST_CONFIG = Path(__file__).parent / "exiftool_cuepointlist.config"


def extract_audio_markers(directory: Path):
    for path in directory.glob("*/recordings/*/rec-*-audio-*-markers.wav"):
        if (markers_path := path.with_suffix(".csv")).is_file():
            logging.info("skipping '%s' ('%s' already exists)", path.name, markers_path.name)
            continue

        logging.info("extracting markers from '%s' to '%s'", path.name, markers_path.name)
        extract_markers_wav(path, markers_path)


def extract_markers_wav(path: Path, output_path: Path):
    output = subprocess.check_output(
        ["exiftool", "-config", str(CUEPOINTLIST_CONFIG), "-cuepointlist", "-b", str(path)]
    ).decode()
    markers = [row.split()[2:4] for row in output.splitlines()[1:]]

    with output_path.open("w", encoding="utf-8", newline="\n") as file:
        writer = csv.writer(file, lineterminator="\n")
        writer.writerow(["time", "rating"])
        writer.writerows(markers)


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    extract_audio_markers(Path(__file__).parent)
