import csv
import json
from pathlib import Path
from typing import Any, cast

from branca import colormap
from branca.colormap import StepColormap, TypeAnyColorType
import folium
import numpy as np
import numpy.typing as npt

from matplotlib import colormaps

Coord = tuple[float, float] | list[float] | npt.NDArray[np.float64]
CoordArray = list[tuple[float, float]] | npt.NDArray[np.float64]

COLORMAP = cast(StepColormap, colormap.linear.Set1_04).scale(1, 12)  # pyright: ignore[reportAttributeAccessIssue]

PARENT_DIRECTORY = Path(__file__).parent

# https://www.movable-type.co.uk/scripts/latlong.html
EARTH_RADIUS = 6371e3


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


def plot_test_map():
    ROUTE = "*e"
    METHOD = "*"

    folium_map = folium.Map(max_zoom=24)

    for path in PARENT_DIRECTORY.glob(f"data/*/recordings/*/rec-*-{METHOD}-{ROUTE}.csv"):
        with path.open(encoding="utf-8") as file:
            reader = csv.reader(file)
            next(reader)
            data = np.array([[float(v) if v.strip() else 0.0 for v in row] for row in reader])
            data = np.hstack((data, np.arange(data.shape[0])[:, np.newaxis]))

        participant_id = path.parents[2].stem
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
        ratings = data[:, 3]
        indices = data[:, 4].astype(int)

        feature_group = folium.FeatureGroup(
            f"{method} {participant_id} ({recording_id})",
            show=False,
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
    folium_map.add_child(folium.LatLngPopup())
    folium_map.show_in_browser()


def load_route(name: str):
    with (PARENT_DIRECTORY / "routes" / f"{name}.json").open(encoding="utf-8") as file:
        json_data: dict[str, Any] = json.load(file)

    route_coordinates: list[tuple[float, float]] = json_data["coordinates"]
    route_road_types: list[str] = json_data["types"]
    return route_coordinates, route_road_types


def get_route_length(route_coordinates: list[tuple[float, float]]):
    return EARTH_RADIUS * sum(
        haversine_distance(np.radians(p1), np.radians(p2))
        for p1, p2 in zip(route_coordinates[:-1], route_coordinates[1:])
    )


def get_relative_route_segment_starts(route_coordinates: list[tuple[float, float]]):
    total_length = get_route_length(route_coordinates) / EARTH_RADIUS
    segment_starts: list[float] = []

    current_length = 0
    for p1, p2 in zip(route_coordinates[:-1], route_coordinates[1:]):
        segment_starts.append(current_length / total_length)
        current_length += haversine_distance(np.radians(p1), np.radians(p2))

    segment_starts.append(1.0)

    return np.array(segment_starts)


def reinterpolate_route(
    route_coordinates: list[tuple[float, float]], route_types: list[str], n_points: int
):
    segment_starts = get_relative_route_segment_starts(route_coordinates)
    new_coords: list[tuple[float, float]] = []
    new_types: list[str] = []
    for fac in np.linspace(0, 1, n_points - 1, endpoint=False):
        segment_index: int = np.argwhere(np.diff(fac >= segment_starts))[0][0]
        relative_fac = (fac - segment_starts[segment_index]) / (
            segment_starts[segment_index + 1] - segment_starts[segment_index]
        )
        new_point = great_circle_point(
            np.radians(route_coordinates[segment_index]),
            np.radians(route_coordinates[segment_index + 1]),
            relative_fac,
        )
        new_coords.append(np.degrees(new_point).tolist())
        new_types.append(route_types[segment_index])

    new_coords.append(route_coordinates[-1])
    new_types.append(route_types[-1])

    return cast(CoordArray, np.array(new_coords)), new_types


def plot_route(route_coordinates: CoordArray, route_types: list[str], name: str = "reference"):
    SET1 = colormaps["Set1"]

    OTHER_COLOR = cast(TypeAnyColorType, SET1.colors[7])  # pyright: ignore[reportAttributeAccessIssue]
    COLOR_MAPPING = cast(
        dict[str, TypeAnyColorType],
        {
            "road": SET1.colors[1],  # pyright: ignore[reportAttributeAccessIssue]
            "bike_path": SET1.colors[4],  # pyright: ignore[reportAttributeAccessIssue]
            "pedestrian_way": SET1.colors[2],  # pyright: ignore[reportAttributeAccessIssue]
            "mixed_path": SET1.colors[3],  # pyright: ignore[reportAttributeAccessIssue]
            "crossing": SET1.colors[0],  # pyright: ignore[reportAttributeAccessIssue]
        },
    )

    unique_road_types: list[str] = np.unique(route_types).tolist()

    road_type_colormap = colormap.StepColormap(
        [COLOR_MAPPING.get(road_type, OTHER_COLOR) for road_type in unique_road_types]
    )
    colors = [
        (unique_road_types.index(road_type) + 0.5) / len(unique_road_types)
        for road_type in route_types
    ]

    feature_group = folium.FeatureGroup(name)

    folium.ColorLine(
        route_coordinates,
        colors,
        colormap=road_type_colormap,
        weight=10,
    ).add_to(feature_group)

    route_types2 = route_types + route_types[-1:]
    for index, (coordinate, road_type) in enumerate(zip(route_coordinates, route_types2)):
        folium.CircleMarker(
            coordinate,
            radius=3,
            fill=True,
            color=COLOR_MAPPING.get(road_type, OTHER_COLOR),  # pyright: ignore[reportArgumentType]
            tooltip=f"{index}",
        ).add_to(feature_group)

    return feature_group


def load_recording(path: Path):
    with path.open(encoding="utf-8") as file:
        reader = csv.reader(file)
        next(reader)
        data = np.array([[float(v) if v.strip() else 0.0 for v in row] for row in reader])
        data = np.hstack((data, np.arange(data.shape[0])[:, np.newaxis]))

    if (filter_path := path.with_stem("filter")).is_file():
        with filter_path.open(encoding="utf-8") as file:
            reader = csv.reader(file)
            next(reader)
            sections = [(int(row[0]), int(row[1])) for row in reader]

        data = np.concatenate([data[np.arange(start, end + 1)] for start, end in sections])
    else:
        print(f"missing filter for {path.name})")

    coordinates = cast(npt.NDArray[np.float64], data[:, 0:2])
    ratings = data[:, 3]

    return coordinates, ratings


def remap_recording_ratings_to_route(
    rec_coords: CoordArray, rec_ratings: npt.NDArray[np.int64], route_coords: CoordArray
):
    remapped_ratings = np.zeros(len(route_coords))

    prev_index = 0
    for coord, rating in zip(rec_coords[1:], rec_ratings):
        dists = [
            haversine_distance(np.radians(coord), np.radians(interp_coord))
            for interp_coord in route_coords
        ]
        index = np.argwhere(np.min(dists) == np.array(dists))[0][0]

        if index > prev_index:
            remapped_ratings[prev_index:index] = rating

        prev_index = index

    remapped_ratings[prev_index:] = rec_ratings[-1]

    print(remapped_ratings)
    return remapped_ratings


def plot_test_route():
    coords, types = load_route("south_route")
    length = get_route_length(coords)
    interp_coords, interp_types = reinterpolate_route(coords, types, round(length) + 1)

    recording_coords, recording_ratings = load_recording(
        PARENT_DIRECTORY
        / "data"
        / "1ae7a"
        / "recordings"
        / "01-a533f"
        / "rec-a533f-mapping-south_route.csv"
    )

    remap_recording_ratings_to_route(recording_coords, recording_ratings, interp_coords)

    folium_map = folium.Map(max_zoom=24)

    plot_route(coords, types, "original").add_to(folium_map)
    plot_route(interp_coords, interp_types, "interp").add_to(folium_map)

    folium.LayerControl().add_to(folium_map)
    folium_map.fit_bounds(folium_map.get_bounds())  # pyright: ignore[reportArgumentType]
    folium_map.add_child(folium.LatLngPopup())
    folium_map.show_in_browser()


# plot_test_map()
# plot_test_route()

from eval_ueq import METHODS  # noqa
from scipy import stats  # noqa

AFTER_CONSTRUCTION_SITE_PARTICIPANTS = ["1ae7a", "94aa4", "f1cff", "b1428", "dd79c", "ca02f"]
ROUTES = ["north_route", "east_route", "south_route", "north_route2", "south_route2"]

all_section_types: set[str] = set()
interp_routes: list[tuple[CoordArray, list[str]]] = []
for route in ROUTES:
    coords, types = load_route(route)
    all_section_types = all_section_types.union(types)

    length = get_route_length(coords)
    interp_routes.append(reinterpolate_route(coords, types, round(length) + 1))

all_section_types_sorted = sorted(all_section_types)

SELECTED_TYPES = all_section_types_sorted.copy()

ratings_per_method_per_type: list[dict[str, list[float]]] = [
    {section_type: [] for section_type in all_section_types_sorted},
    {section_type: [] for section_type in all_section_types_sorted},
    {section_type: [] for section_type in all_section_types_sorted},
]
for path in PARENT_DIRECTORY.glob("data/*/recordings/*/rec-*-*-*route.csv"):
    participant_id = path.parents[2].stem
    method, route = path.stem.split("-")[2:4]

    index = ROUTES.index(route)
    if participant_id in AFTER_CONSTRUCTION_SITE_PARTICIPANTS:
        if index == 0:
            index = 3
        elif index == 2:
            index = 4

    coords, ratings = load_recording(path)
    interp_coords, interp_types = interp_routes[index]
    interp_ratings = remap_recording_ratings_to_route(coords, ratings, interp_coords)

    print(len(interp_types), len(interp_ratings))
    for type, rating in zip(interp_types, interp_ratings):
        ratings_per_method_per_type[METHODS.index(method)][type].append(rating)

    print(participant_id, method, route, ROUTES[index], path.stem)

for i, method in enumerate(METHODS):
    print()
    print(method.upper())
    for section_type in SELECTED_TYPES:
        ratings = ratings_per_method_per_type[i][section_type]
        confidence_level = 1 - 0.05
        mean = np.mean(ratings)
        scale: float = np.std(ratings) / np.sqrt(len(ratings))
        confidence_interval = (
            cast(
                tuple[float, float],
                stats.t.interval(confidence_level, len(ratings) - 1, loc=mean, scale=scale),
            )
            if scale
            else (mean, mean)
        )
        print(
            section_type,
            ": ",
            f"{np.mean(ratings):.4f}",
            f"{np.var(ratings):.4f}",
            f"{np.std(ratings):.4f}",
            f"{confidence_interval[0]:.4f}",
            f"{confidence_interval[1]:.4f}",
        )
