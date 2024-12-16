import csv
import logging
import sys
from pathlib import Path

import numpy as np


def write_markers_to_recordings(directory: Path):
    for path in directory.glob("*/recordings/*/rec-*-audio-*.csv"):
        if not can_write_to_recording(path):
            continue
        logging.info("writing markers to '%s'", path.name)
        write_audio_markers_to_recording(path)

    for path in directory.glob("*/recordings/*/rec-*-mapping-*.csv"):
        if not can_write_to_recording(path):
            continue
        logging.info("writing markers to '%s'", path.name)
        write_mapping_markers_to_recording(path)


def can_write_to_recording(path: Path):
    if path.stem.endswith("-markers"):
        return False
    if not (markers_path := get_markers_path(path)).is_file():
        return False
    if (backup_path := get_backup_path(path)).is_file():
        logging.info(
            "skipping '%s' ('%s' exists, already wrote markers)",
            markers_path.name,
            backup_path.name,
        )
        return False
    return True


def write_audio_markers_to_recording(path: Path):
    with get_markers_path(path).open(encoding="utf-8") as file:
        reader = csv.reader(file)
        next(reader)
        markers = [(float(row[0]), int(row[1])) for row in reader]

    with path.open(encoding="utf-8") as file:
        data = [row for row in csv.reader(file)]

    timestamps = np.array([int(row[2]) / 1000 for row in data[1:]])
    ratings = np.zeros(len(timestamps), dtype=np.uint8)

    # extrapolate ratings at start, end
    markers[0] = (timestamps.min() - 1, markers[0][1])
    markers.append((timestamps.max() + 1, 0))

    for (start, rating), (end, _) in zip(markers[:-1], markers[1:]):
        ratings[np.where((timestamps >= start) & (timestamps < end))] = rating

    path.rename(get_backup_path(path))
    with path.open("w", encoding="utf-8", newline="\n") as file:
        writer = csv.writer(file, lineterminator="\n")
        writer.writerow(data[0])
        rating: int
        for row, rating in zip(data[1:], ratings):
            writer.writerow(row[:-1] + [f" {rating}"])


def write_mapping_markers_to_recording(path: Path):
    with get_markers_path(path).open(encoding="utf-8") as file:
        reader = csv.reader(file)
        next(reader)
        markers = [(float(row[0]), int(row[1])) for row in reader]

    with path.open(encoding="utf-8") as file:
        data = [row for row in csv.reader(file)]

    ratings = np.zeros(len(data) - 1, dtype=np.uint8)

    # extrapolate ratings at end
    markers.append((len(ratings), 0))

    for (start, rating), (end, _) in zip(markers[:-1], markers[1:]):
        ratings[np.arange(start, end, dtype=int)] = rating

    path.rename(get_backup_path(path))
    with path.open("w", encoding="utf-8", newline="\n") as file:
        writer = csv.writer(file, lineterminator="\n")
        writer.writerow(data[0])
        rating: int
        for row, rating in zip(data[1:], ratings):
            writer.writerow(row[:-1] + [f" {rating}"])


def get_markers_path(path: Path):
    return path.with_stem(path.stem + "-markers")


def get_backup_path(path: Path):
    return path.with_suffix(".csv.bak")


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    write_markers_to_recordings(Path(__file__).parent)
