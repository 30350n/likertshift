import json
from itertools import combinations
from pathlib import Path
from typing import cast

from branca.colormap import TypeAnyColorType
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import colormaps
from matplotlib.axes import Axes
from numpy.typing import NDArray
from scipy import stats

METHODS = ("device", "audio", "mapping")
UEQ_SCALES = (
    "attractiveness",
    "efficiency",
    "intuitive_use",
    "hardware_safety",
    "social_acceptance",
)
PAD = max(map(len, UEQ_SCALES)) + 1
SCALE_RANGE = 5


def load_json(path: Path):
    with path.open(encoding="utf-8") as file:
        data: dict[str, float] = json.load(file)
    return np.array(list(data.values()))


def confidence_interval(alpha: float, data: NDArray[np.float64]):
    confidence_level = 1 - alpha
    mean = np.mean(data)
    scale: float = np.std(data) / np.sqrt(data.size)
    confidence_interval = cast(
        tuple[float, float],
        stats.t.interval(confidence_level, data.size - 1, loc=mean, scale=scale),
    )
    return confidence_interval


def cronbach_alpha(data: NDArray[np.float64]):
    k = data.shape[1]
    correlations = [
        cast(float, stats.pearsonr(data[:, i], data[:, j]).statistic)  # pyright: ignore[reportAttributeAccessIssue]
        for i, j in combinations(range(k), 2)
    ]
    mean_correlation = np.mean(correlations)
    return k * mean_correlation / (1 + (k - 1) * mean_correlation)


def evaluate(directory: Path):
    ys = np.empty((len(METHODS), len(UEQ_SCALES)))
    errors = np.empty(ys.shape)
    cronbachs = np.empty(ys.shape)
    participant_means: NDArray[np.float64] = np.zeros((len(UEQ_SCALES), len(METHODS), 18))

    for i, method in enumerate(METHODS):
        print(
            method.upper().ljust(PAD)
            + "    MEAN  VARIANCE  STDDEV   N  CONFIDENCE INTERVAL  CRONBACH"
        )

        for j, scale in enumerate(UEQ_SCALES):
            pattern = f"*/recordings/*/rec-*-{method}-*_ueq_*_{scale}.json"
            arrays = [
                load_json(path)
                for path in sorted(directory.glob(pattern), key=lambda path: path.parents[2])
            ]
            data = np.vstack(arrays)
            data = (data - 1.0) / (SCALE_RANGE - 1.0) * 2.0 - 1.0

            n = data.shape[0]
            mean = np.mean(data)
            variance = np.var(data)
            stddev = np.std(data)
            interval = confidence_interval(0.05, data)
            cronbach = cronbach_alpha(data)

            participant_means[j, i] = np.mean(data, axis=1)

            ys[i, j] = mean
            errors[i, j] = (interval[1] - interval[0]) / 2
            cronbachs[i, j] = cronbach

            scale_name = f"{scale}:".replace("_", " ").ljust(PAD)
            print(
                f"{scale_name}  {mean: .3f}    {variance: .3f}  {stddev: .3f}  {n:2}"
                + f"     {interval[0]: .3f}  - {interval[1]: .3f}    {cronbach: .3f}"
            )

        print()

    WILLCOXON_VARIANTS = "  ".join(
        f"WILCOXON {m1[0]}:{m2[0]}".upper() for m1, m2 in combinations(METHODS, 2)
    )
    print("SCALE".ljust(PAD) + f"  FRIEDMAN  {WILLCOXON_VARIANTS}")
    friedman_ps = []
    for j, scale in enumerate(UEQ_SCALES):
        friedman_p = stats.friedmanchisquare(*participant_means[j]).pvalue
        friedman_ps.append(friedman_p)
        wilcoxon_ps = [
            cast(float, stats.wilcoxon(participant_means[j, i1], participant_means[j, i2]).pvalue)  # pyright: ignore[reportAttributeAccessIssue]
            for i1, i2 in combinations(range(3), 2)
        ]

        scale_name = f"{scale}:".replace("_", " ").ljust(PAD)
        print(
            f"{scale_name}  {friedman_p:.6f}      "
            + f"{wilcoxon_ps[0]:.6f}      {wilcoxon_ps[1]:.6f}      {wilcoxon_ps[2]:.6f}"
        )

    TITLES = [" ".join(word.capitalize() for word in scale.split("_")) for scale in UEQ_SCALES]
    PASTEL1 = colormaps["Pastel1"]
    COLORS: list[TypeAnyColorType] = [PASTEL1.colors[1], PASTEL1.colors[0], PASTEL1.colors[4]]  # pyright: ignore[reportAttributeAccessIssue]
    HATCHES = (None, "//", "\\\\")
    LABELS = ("LikertShift", "Audio Recording", "Mapping")
    ECOLOR = np.ones(3) * 0.2
    BAR_KWARGS = dict(
        edgecolor="gray", capsize=5, ecolor=ECOLOR, error_kw={"elinewidth": 1.5, "capthick": 1.5}
    )

    axes: list[Axes]
    fig, axes = plt.subplots(1, len(UEQ_SCALES), figsize=(10.15, 6), sharey=True)

    for i, (scale, ax, title) in enumerate(zip(UEQ_SCALES, axes, TITLES)):
        for j, (method, color, hatch, label) in enumerate(zip(METHODS, COLORS, HATCHES, LABELS)):
            ax.bar(
                j,
                ys[j, i],
                yerr=errors[j, i],
                color=color,
                hatch=hatch,
                label=label,
                **BAR_KWARGS,  # pyright: ignore[reportArgumentType]
            )

        ax.set_title(title)
        ax.hlines(0, -1, len(METHODS), colors="gray", linestyles="dashed", zorder=-1)
        ax.set_xticks([])
        ax.set_xlim(-1, len(METHODS))
        ax.set_ylim(-0.4, 1)
        p_text = f"$p={friedman_ps[i]:.3f}$" if friedman_ps[i] >= 0.001 else "$p<0.001$"
        ax.text(0.5, -0.06, p_text, ha="center", size=12, transform=ax.transAxes)

    handles, labels = axes[-1].get_legend_handles_labels()
    fig.legend(
        handles,
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 0.07),
        ncols=len(METHODS),
        prop={"size": 12.5},
        columnspacing=2,
    )

    plt.tight_layout(rect=(0, 0.05, 0.96, 1))
    plt.savefig("eval_ueq.pdf")


if __name__ == "__main__":
    evaluate(Path(__file__).parent / "data")
