"""Shared matplotlib styling: validated categorical/sequential/status palette,
applied consistently across every chart in outputs/plots/."""

import matplotlib

try:
    get_ipython()  # noqa: F821 -- only defined inside an IPython/Jupyter kernel
    _IN_NOTEBOOK = True
except NameError:
    _IN_NOTEBOOK = False

if not _IN_NOTEBOOK:
    # Headless script run: force Agg so we only save PNGs, never try to open
    # an interactive window (the Tk backend crashes under this machine's
    # locked-down DLL policy). Inside a notebook kernel, leave the backend
    # alone so matplotlib-inline can render figures in the cell output.
    matplotlib.use("Agg")

import matplotlib.pyplot as plt

# Validated categorical palette (light mode), fixed hue order -- never cycle
# past what's needed, never reorder per-chart.
CATEGORICAL = [
    "#2a78d6",  # blue
    "#008300",  # green
    "#e87ba4",  # magenta
    "#eda100",  # yellow
    "#1baf7a",  # aqua
    "#eb6834",  # orange
    "#4a3aa7",  # violet
    "#e34948",  # red
]

# Sequential blue ramp, light -> dark
SEQUENTIAL_BLUE = ["#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#256abf", "#184f95", "#0d366b"]

# Diverging blue <-> red, neutral midpoint
DIVERGING = {"low": "#2a78d6", "mid": "#f0efec", "high": "#e34948"}

# Status colors -- reserved for risk/good-bad meaning, never reused as series colors
STATUS = {
    "good": "#0ca30c",
    "warning": "#fab219",
    "serious": "#ec835a",
    "critical": "#d03b3b",
}

# Chart chrome
SURFACE = "#fcfcfb"
INK_PRIMARY = "#0b0b0b"
INK_SECONDARY = "#52514e"
INK_MUTED = "#898781"
GRIDLINE = "#e1e0d9"
BASELINE = "#c3c2b7"

CHURN_COLOR = STATUS["critical"]
RETAINED_COLOR = CATEGORICAL[0]


def apply_style():
    plt.rcParams.update({
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "axes.edgecolor": BASELINE,
        "axes.labelcolor": INK_SECONDARY,
        "axes.titlecolor": INK_PRIMARY,
        "text.color": INK_PRIMARY,
        "xtick.color": INK_MUTED,
        "ytick.color": INK_MUTED,
        "grid.color": GRIDLINE,
        "grid.linewidth": 0.8,
        "axes.grid": True,
        "axes.grid.axis": "y",
        "axes.spines.top": False,
        "axes.spines.right": False,
        "font.family": "sans-serif",
        "font.size": 10,
        "figure.dpi": 110,
        "savefig.dpi": 110,
        "savefig.facecolor": SURFACE,
    })
