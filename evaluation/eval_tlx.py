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

from eval_questionnaires import load_json, METHODS, confidence_interval

TLX_SCALES = (
    "mental_demand",
    "physical_demand",
    "temporal_demand",
    "performance",
    "effort",
    "frustration",
)
PAD = max(map(len, TLX_SCALES)) + 1
SCALE_RANGE = 10


def evaluate(directory: Path):
    ys = np.empty((len(METHODS), len(TLX_SCALES)))
    errors = np.empty(ys.shape)
    participant_ratings: NDArray[np.float64] = np.zeros((len(TLX_SCALES), len(METHODS), 18))

    for i, method in enumerate(METHODS):
        print(method.upper().ljust(PAD) + "    MEAN  VARIANCE  STDDEV   N  CONFIDENCE INTERVAL")

        pattern = f"*/recordings/*/rec-*-{method}-*_tlx.json"
        arrays = [
            load_json(path)
            for path in sorted(directory.glob(pattern), key=lambda path: path.parents[2])
        ]
        data = np.vstack(arrays)
        data = data / SCALE_RANGE
        n = data.shape[0]

        participant_ratings[:, i] = data.T

        for j, scale in enumerate(TLX_SCALES):
            mean = np.mean(data[:, j])
            variance = np.var(data[:, j])
            stddev = np.std(data[:, j])
            interval = confidence_interval(0.05, data[:, j])

            ys[i, j] = mean
            errors[i, j] = (interval[1] - interval[0]) / 2

            scale_name = f"{scale}:".replace("_", " ").ljust(PAD)
            print(
                f"{scale_name}  {mean: .3f}    {variance: .3f}  {stddev: .3f}  {n:2}"
                + f"     {interval[0]: .3f}  - {interval[1]: .3f}"
            )

        print()

    WILLCOXON_VARIANTS = "  ".join(
        f"WILCOXON {m1[0]}:{m2[0]}".upper() for m1, m2 in combinations(METHODS, 2)
    )
    print("SCALE".ljust(PAD) + f"  FRIEDMAN  {WILLCOXON_VARIANTS}")
    friedman_ps: list[float] = []
    for j, scale in enumerate(TLX_SCALES):
        friedman_p = cast(float, stats.friedmanchisquare(*participant_ratings[j]).pvalue)
        friedman_ps.append(friedman_p)
        wilcoxon_ps = [
            cast(
                float,
                stats.wilcoxon(participant_ratings[j, i1], participant_ratings[j, i2]).pvalue,  # pyright: ignore[reportAttributeAccessIssue]
            )
            for i1, i2 in combinations(range(3), 2)
        ]

        scale_name = f"{scale}:".replace("_", " ").ljust(PAD)
        print(
            f"{scale_name}  {friedman_p:.6f}      "
            + f"{wilcoxon_ps[0]:.6f}      {wilcoxon_ps[1]:.6f}      {wilcoxon_ps[2]:.6f}"
        )

    TITLES = [" ".join(word.capitalize() for word in scale.split("_")) for scale in TLX_SCALES]
    PASTEL1 = colormaps["Pastel1"]
    COLORS: list[TypeAnyColorType] = [PASTEL1.colors[1], PASTEL1.colors[0], PASTEL1.colors[4]]  # pyright: ignore[reportAttributeAccessIssue]
    HATCHES = (None, "//", "\\\\")
    LABELS = ("LikertShift", "Audio Recording", "Mapping")
    ECOLOR = np.ones(3) * 0.2
    BAR_KWARGS = dict(
        edgecolor="gray", capsize=5, ecolor=ECOLOR, error_kw={"elinewidth": 1.5, "capthick": 1.5}
    )

    axes: list[Axes]
    fig, axes = plt.subplots(1, len(TLX_SCALES), figsize=(12, 6), sharey=True)

    for i, (scale, ax, title) in enumerate(zip(TLX_SCALES, axes, TITLES)):
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
        ax.set_ylim(-0.4, 0.3)
        p_text = f"$p={friedman_ps[i]:.3f}$" if friedman_ps[i] >= 0.001 else "$p<0.001$"
        ax.text(0.5, -0.06, p_text, ha="center", size=12, transform=ax.transAxes)

    # axes[0].set_ylabel("Rating", fontsize=12.5)
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
    # axes[-1].legend(loc="upper center", , ncol=len(METHODS))

    plt.tight_layout(rect=(0, 0.05, 0.965, 1))
    plt.savefig("eval_tlx.pdf")
    # plt.show()


if __name__ == "__main__":
    evaluate(Path(__file__).parent / "data")
