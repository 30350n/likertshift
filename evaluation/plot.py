import csv
from pathlib import Path
from typing import cast

from branca import colormap
from branca.colormap import StepColormap
import folium
import numpy as np
import numpy.typing as npt

Coord = tuple[float, float] | list[float] | npt.NDArray[np.float64]
CoordArray = list[tuple[float, float]] | npt.NDArray[np.float64]

COLORMAP = cast(StepColormap, colormap.linear.Set1_04).scale(1, 12)  # pyright: ignore[reportAttributeAccessIssue]

# https://www.movable-type.co.uk/scripts/latlong.html


def haversine_distance(p1: Coord, p2: Coord) -> float:
    a: float = (
        np.sin((p2[0] - p1[0]) / 2) ** 2
        + np.cos(p1[0]) * np.cos(p2[0]) * np.sin((p2[1] - p1[1]) / 2) ** 2
    )
    sqrt_a: float = np.sqrt(a)
    result: float = 2 * np.arcsin(sqrt_a)
    return result


def initial_bearing(p1: Coord, p2: Coord) -> float:
    y: float = np.sin(p2[1] - p1[1]) * np.cos(p2[0])
    x: float = np.cos(p1[0]) * np.sin(p2[0]) - np.sin(p1[0]) * np.cos(p2[0]) * np.cos(p2[1] - p1[1])
    result: float = np.arctan2(y, x)
    return result


def great_circle_point(p1: Coord, p2: Coord, x: float = 0.5):
    distance = haversine_distance(p1, p2)
    bearing = initial_bearing(p1, p2)

    dx = distance * x

    lat_inner: float = np.sin(p1[0]) * np.cos(dx) + np.cos(p1[0]) * np.sin(dx) * np.cos(bearing)
    lat: float = np.arcsin(lat_inner)
    inner_y: float = np.sin(bearing) * np.sin(dx) * np.cos(p1[0])
    inner_x: float = np.cos(dx) - np.sin(p1[0]) * np.sin(lat)
    long: float = p1[1] + np.arctan2(inner_y, inner_x)
    return (lat, long)


def closest_point_on_great_circle(p1: Coord, p2: Coord, p3: Coord):
    bearing_1_to_2 = initial_bearing(p1, p2)
    distance_1_to_2 = haversine_distance(p1, p2)
    bearing_1_to_3 = initial_bearing(p1, p3)
    distance_1_to_3 = haversine_distance(p1, p3)

    inner_cross_track: float = np.sin(distance_1_to_3) * np.sin(bearing_1_to_3 - bearing_1_to_2)
    cross_track_distance: float = np.arcsin(inner_cross_track)

    inner_along_track: float = np.cos(distance_1_to_3) / np.cos(cross_track_distance)
    along_track_distance: float = np.arccos(inner_along_track)

    return great_circle_point(p1, p2, along_track_distance / distance_1_to_2)


def test_math():
    point_a = (52.533685, 13.271484)
    point_b = (41.753841, 65.566406)
    point_c = (44.949776, 28.125000)

    point_a_rad: Coord = np.radians(point_a).tolist()
    point_b_rad: Coord = np.radians(point_b).tolist()
    point_c_rad: Coord = np.radians(point_c).tolist()

    point_d_rad: Coord = closest_point_on_great_circle(point_a_rad, point_b_rad, point_c_rad)
    point_d: list[float] = np.degrees(point_d_rad).tolist()

    folium_map = folium.Map()

    xs: list[float] = np.linspace(0, 1, 128).tolist()
    folium.PolyLine(
        [np.degrees(great_circle_point(point_a_rad, point_b_rad, x)) for x in xs],
    ).add_to(folium_map)
    folium.CircleMarker(point_a).add_to(folium_map)
    folium.CircleMarker(point_b).add_to(folium_map)
    folium.CircleMarker(point_c).add_to(folium_map)
    folium.CircleMarker(point_d).add_to(folium_map)
    folium_map.show_in_browser()


folium_map = folium.Map(max_zoom=24)

for i, path in enumerate(Path(__file__).parent.glob("data/*/recordings/*/rec-*-audio-*e.csv")):
    with path.open(encoding="utf-8") as file:
        reader = csv.reader(file)
        next(reader)
        data = np.array([[float(v) if v.strip() else 0.0 for v in row] for row in reader])
        data = np.hstack((data, np.arange(data.shape[0])[:, np.newaxis]))

    participant_id = path.parent.parent.parent.stem
    recording_id, method = path.stem.split("-")[1:3]

    if (filter_path := path.with_stem("filter")).is_file():
        with filter_path.open(encoding="utf-8") as file:
            reader = csv.reader(file)
            next(reader)
            sections = [(int(row[0]), int(row[1])) for row in reader]

        data = np.concatenate([data[np.arange(start, end + 1)] for start, end in sections])
    else:
        print(f"missing filter for {path.name})")

    coordinates = data[:, 0:2]
    times = data[:, 2]
    ratings = data[:, 3]
    indices = data[:, 4].astype(int)

    if np.all(ratings == ratings[0]):  # pyright: ignore[reportAny]
        pass  # continue

    feature_group = folium.FeatureGroup(
        f"{method} {participant_id} ({recording_id})",
    ).add_to(folium_map)

    folium.ColorLine(
        coordinates,
        colors=ratings,
        colormap=COLORMAP,
        weight=5,
    ).add_to(feature_group)

    coordinate: tuple[float, float]
    index: int
    rating: float
    for index, coordinate, rating in zip(indices, coordinates, ratings):
        folium.CircleMarker(
            coordinate,
            radius=3,
            fill=True,
            color=COLORMAP(rating),
            tooltip=f"{index} ({rating}, {participant_id} {recording_id})",
        ).add_to(feature_group)

folium.LayerControl().add_to(folium_map)
folium_map.fit_bounds(folium_map.get_bounds())  # pyright: ignore[reportArgumentType]
folium_map.show_in_browser()
